// "Close your macros": suggests foods that fit what's left of today's calories and protein.

import { FOODS } from './foods.js';

const SKIP = new Set(['Drinks', 'Desserts & sweets']);

export function suggestFoods(remainingKcal, remainingProtein, { limit = 3, pool = FOODS } = {}) {
  if (remainingKcal < 120) return [];
  const needProtein = remainingProtein > 15;
  return pool
    .filter((f) => !SKIP.has(f.category) && f.calories > 40 && f.calories <= remainingKcal * 1.05)
    .map((f) => {
      const density = f.protein / Math.max(1, f.calories); // grams of protein per kcal
      const fill = f.calories / remainingKcal; // how much of the gap it closes
      const proteinFit = needProtein ? Math.min(1, f.protein / remainingProtein) : 0;
      const score = needProtein ? density * 100 + proteinFit * 2 + fill : fill * 3 + density * 5;
      return { food: f, score };
    })
    .sort((a, b) => b.score - a.score)
    .filter(diverse())
    .slice(0, limit)
    .map((s) => s.food);
}

// At most one suggestion per food category, so it's not three kinds of fish.
function diverse() {
  const seen = new Set();
  return ({ food }) => {
    if (seen.has(food.category)) return false;
    seen.add(food.category);
    return true;
  };
}
