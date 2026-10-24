// Daily targets from body stats (Mifflin-St Jeor BMR × activity factor).

export const ACTIVITY_LEVELS = [
  { value: 1.2, label: 'Sedentary', hint: 'Desk job, little exercise' },
  { value: 1.375, label: 'Light', hint: 'Exercise 1–3 days/week' },
  { value: 1.55, label: 'Moderate', hint: 'Exercise 3–5 days/week' },
  { value: 1.725, label: 'Very active', hint: 'Hard training 6–7 days/week' },
  { value: 1.9, label: 'Athlete', hint: 'Physical job + daily training' },
];

export const GOALS = {
  cut: { label: 'Cut', hint: 'Lose fat, keep muscle', calorieFactor: 0.8, proteinPerKg: 2.2, emoji: '🔥' },
  maintain: { label: 'Maintain', hint: 'Recomp & stay lean', calorieFactor: 1.0, proteinPerKg: 1.8, emoji: '⚖️' },
  bulk: { label: 'Bulk', hint: 'Build muscle', calorieFactor: 1.1, proteinPerKg: 1.8, emoji: '💪' },
};

// Calories may land anywhere in this window (as a fraction of the goal) to count as "on target".
export const TARGET_WINDOW = {
  cut: [0.85, 1.03],
  maintain: [0.9, 1.1],
  bulk: [0.97, 1.15],
};

export function bmr({ sex, weightKg, heightCm, age }) {
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return sex === 'female' ? base - 161 : base + 5;
}

export const isMinor = (profile) => (profile.age || 0) < 18;

export function computeTargets(profile) {
  const goal = GOALS[profile.goal] || GOALS.maintain;
  const tdee = bmr(profile) * (profile.activity || 1.375);
  const floor = profile.sex === 'female' ? 1200 : 1500;
  // Teens are still growing: never set a calorie deficit for under-18s.
  const factor = isMinor(profile) ? Math.max(1, goal.calorieFactor) : goal.calorieFactor;
  const calories = Math.max(floor, Math.round((tdee * factor) / 10) * 10);
  const protein = Math.min(250, Math.round(profile.weightKg * goal.proteinPerKg));
  const fat = Math.round((calories * 0.27) / 9);
  const carbs = Math.max(0, Math.round((calories - protein * 4 - fat * 9) / 4));
  return { tdee: Math.round(tdee), calories, protein, carbs, fat };
}

export function bmi(weightKg, heightCm) {
  const m = heightCm / 100;
  return weightKg / (m * m);
}

// Unit conversions used by the forms.
export const kgToLb = (kg) => kg * 2.2046226218;
export const lbToKg = (lb) => lb / 2.2046226218;
export const cmToIn = (cm) => cm / 2.54;
export const inToCm = (inch) => inch * 2.54;

export function cmToFtIn(cm) {
  let totalIn = Math.round(cmToIn(cm));
  return { ft: Math.floor(totalIn / 12), inch: totalIn % 12 };
}
