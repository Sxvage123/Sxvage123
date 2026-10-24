// Built-in nutrition database (typical USDA values per common serving), plus helpers to map
// on-device food-recognition labels to entries. Format: [name, serving, kcal, protein, carbs, fat, aliases]

const RAW = {
  Breakfast: [
    ['Scrambled eggs', '2 large eggs', 182, 12, 2, 14, 'egg eggs scrambled'],
    ['Fried egg', '1 large egg', 90, 6, 0.4, 7, 'egg sunny side'],
    ['Boiled egg', '1 large egg', 78, 6, 0.6, 5, 'hard boiled egg'],
    ['Omelette (3 egg, cheese)', '1 omelette', 400, 25, 3, 31, 'omelet'],
    ['Egg whites', '1 cup', 126, 26, 2, 0.4, ''],
    ['Pancakes with syrup', '3 pancakes', 520, 10, 90, 14, 'pancake hotcakes'],
    ['Waffle', '1 large waffle', 310, 8, 38, 14, 'waffles'],
    ['French toast', '2 slices', 360, 12, 40, 16, ''],
    ['Oatmeal (cooked)', '1 cup', 166, 6, 28, 4, 'porridge oats'],
    ['Overnight oats', '1 jar', 350, 14, 52, 10, ''],
    ['Granola', '1/2 cup', 300, 7, 37, 15, ''],
    ['Cereal with milk', '1 bowl', 250, 8, 42, 5, 'cornflakes cheerios'],
    ['Greek yogurt (plain, nonfat)', '170 g cup', 100, 17, 6, 0.7, 'yoghurt'],
    ['Greek yogurt (flavored)', '150 g cup', 140, 12, 18, 2.5, 'yoghurt'],
    ['Yogurt parfait', '1 cup', 280, 10, 45, 7, ''],
    ['Bagel with cream cheese', '1 bagel', 390, 12, 58, 12, 'bagel'],
    ['Plain bagel', '1 bagel', 270, 11, 53, 1.5, ''],
    ['Croissant', '1 croissant', 270, 5, 31, 14, ''],
    ['Breakfast burrito', '1 burrito', 550, 25, 45, 29, ''],
    ['Breakfast sandwich (egg, cheese, bacon)', '1 sandwich', 450, 20, 33, 26, 'egg mcmuffin'],
    ['Bacon', '3 strips', 130, 9, 0.4, 10, ''],
    ['Sausage links', '2 links', 170, 8, 1, 15, 'breakfast sausage'],
    ['Hash browns', '1 cup', 320, 3, 35, 19, 'hash brown'],
    ['Avocado toast', '1 slice', 260, 6, 26, 15, ''],
    ['Toast with butter', '1 slice', 120, 3, 14, 6, 'toast'],
    ['Peanut butter toast', '1 slice', 280, 10, 22, 17, ''],
    ['Eggs Benedict', '2 halves', 700, 30, 32, 50, ''],
    ['Chia pudding', '1 cup', 280, 8, 30, 15, ''],
    ['Acai bowl', '1 bowl', 500, 7, 85, 15, 'açaí'],
  ],
  'Fruit': [
    ['Apple', '1 medium', 95, 0.5, 25, 0.3, ''],
    ['Banana', '1 medium', 105, 1.3, 27, 0.4, ''],
    ['Orange', '1 medium', 62, 1.2, 15, 0.2, ''],
    ['Strawberries', '1 cup', 49, 1, 12, 0.5, 'strawberry'],
    ['Blueberries', '1 cup', 84, 1.1, 21, 0.5, 'blueberry'],
    ['Grapes', '1 cup', 104, 1.1, 27, 0.2, 'grape'],
    ['Watermelon', '2 cups diced', 92, 1.8, 23, 0.5, ''],
    ['Pineapple', '1 cup', 82, 0.9, 22, 0.2, ''],
    ['Mango', '1 cup', 99, 1.4, 25, 0.6, ''],
    ['Pear', '1 medium', 101, 0.6, 27, 0.2, ''],
    ['Peach', '1 medium', 59, 1.4, 14, 0.4, ''],
    ['Avocado', '1/2 avocado', 120, 1.5, 6, 11, ''],
    ['Fruit salad', '1 cup', 90, 1, 23, 0.3, 'fruit cup'],
    ['Raisins', '1/4 cup', 120, 1, 32, 0.2, ''],
    ['Kiwi', '1 fruit', 42, 0.8, 10, 0.4, ''],
    ['Cherries', '1 cup', 87, 1.5, 22, 0.3, ''],
  ],
  'Vegetables & sides': [
    ['Garden salad (no dressing)', '2 cups', 35, 2, 7, 0.3, 'green salad'],
    ['Caesar salad', '1 bowl', 360, 10, 14, 30, ''],
    ['Greek salad', '1 bowl', 250, 6, 12, 20, ''],
    ['Chicken salad (grilled)', '1 bowl', 380, 35, 12, 20, 'cobb salad'],
    ['Potato salad', '1 cup', 360, 7, 28, 21, ''],
    ['Coleslaw', '1 cup', 290, 2, 15, 25, ''],
    ['Steamed broccoli', '1 cup', 55, 4, 11, 0.6, 'broccoli'],
    ['Mixed vegetables', '1 cup', 80, 4, 16, 0.5, 'veggies'],
    ['Roasted vegetables', '1 cup', 140, 3, 16, 7, ''],
    ['Green beans', '1 cup', 44, 2, 10, 0.4, ''],
    ['Corn on the cob', '1 ear', 90, 3, 19, 1.4, 'corn'],
    ['Baked potato (plain)', '1 medium', 160, 4, 37, 0.2, 'potato'],
    ['Loaded baked potato', '1 potato', 450, 13, 50, 22, ''],
    ['Mashed potatoes', '1 cup', 240, 4, 35, 9, 'mashed potato'],
    ['Sweet potato', '1 medium', 112, 2, 26, 0.1, ''],
    ['French fries', 'medium serving', 365, 4, 48, 17, 'fries chips'],
    ['Sweet potato fries', 'medium serving', 380, 3, 50, 18, ''],
    ['Onion rings', '8 rings', 330, 4, 37, 19, ''],
    ['Side salad with dressing', '1 bowl', 150, 2, 8, 12, ''],
    ['Hummus', '1/4 cup', 100, 5, 9, 6, ''],
    ['Guacamole', '1/4 cup', 110, 1, 6, 10, ''],
    ['Edamame', '1 cup', 190, 17, 15, 8, ''],
    ['Spinach (cooked)', '1 cup', 41, 5, 7, 0.5, ''],
    ['Carrots', '1 cup', 52, 1.2, 12, 0.3, 'carrot'],
    ['Cucumber', '1 cup', 16, 0.7, 4, 0.1, ''],
  ],
  'Grains & bread': [
    ['White rice (cooked)', '1 cup', 205, 4, 45, 0.4, 'rice steamed rice'],
    ['Brown rice (cooked)', '1 cup', 216, 5, 45, 1.8, ''],
    ['Fried rice', '1 cup', 330, 8, 45, 13, ''],
    ['Quinoa (cooked)', '1 cup', 222, 8, 39, 3.6, ''],
    ['Pasta (cooked, plain)', '1 cup', 220, 8, 43, 1.3, 'noodles'],
    ['White bread', '1 slice', 75, 2.6, 14, 1, 'bread'],
    ['Whole wheat bread', '1 slice', 80, 4, 14, 1, ''],
    ['Tortilla (flour)', '1 large', 210, 6, 35, 5, ''],
    ['Garlic bread', '1 slice', 170, 4, 20, 8, ''],
    ['Dinner roll', '1 roll', 110, 3, 19, 2, 'bun'],
    ['Cornbread', '1 piece', 200, 4, 30, 7, ''],
    ['Naan', '1 piece', 260, 9, 45, 5, ''],
    ['Pita bread', '1 pita', 165, 5, 33, 0.7, ''],
    ['Couscous', '1 cup', 176, 6, 36, 0.3, ''],
  ],
  'Meat, fish & protein': [
    ['Grilled chicken breast', '6 oz (170 g)', 280, 53, 0, 6, 'chicken breast'],
    ['Chicken thigh (roasted)', '2 thighs', 360, 38, 0, 22, ''],
    ['Rotisserie chicken', '1/4 chicken', 400, 45, 0, 24, 'roast chicken'],
    ['Fried chicken', '2 pieces', 560, 40, 18, 36, 'crispy chicken'],
    ['Chicken wings', '6 wings', 480, 36, 4, 34, 'buffalo wings'],
    ['Chicken nuggets', '10 pieces', 450, 24, 27, 28, 'nuggets'],
    ['Chicken tenders', '4 tenders', 480, 32, 28, 26, 'chicken strips'],
    ['Steak (sirloin)', '8 oz (225 g)', 460, 62, 0, 22, 'beef steak'],
    ['Ribeye steak', '10 oz (280 g)', 790, 66, 0, 58, ''],
    ['Ground beef (80/20, cooked)', '4 oz', 290, 20, 0, 23, ''],
    ['Ground turkey (cooked)', '4 oz', 230, 27, 0, 13, ''],
    ['Pork chop', '1 chop', 280, 35, 0, 15, ''],
    ['Pulled pork', '1 cup', 420, 36, 10, 26, ''],
    ['BBQ ribs', '1/2 rack', 800, 55, 20, 55, 'ribs'],
    ['Meatballs', '4 meatballs', 320, 20, 10, 22, ''],
    ['Salmon fillet', '6 oz (170 g)', 350, 38, 0, 21, 'salmon'],
    ['Tuna (canned in water)', '1 can', 120, 26, 0, 1, 'tuna'],
    ['Shrimp (cooked)', '6 oz', 170, 36, 0, 2, 'prawns'],
    ['Fish and chips', '1 plate', 900, 35, 90, 45, ''],
    ['White fish (baked)', '6 oz', 180, 38, 0, 2, 'cod tilapia'],
    ['Tofu (firm)', '1/2 block', 180, 20, 4, 11, ''],
    ['Protein shake', '1 scoop + water', 120, 24, 3, 1.5, 'whey shake'],
    ['Protein shake with milk', '1 scoop + milk', 250, 32, 15, 6, ''],
    ['Protein bar', '1 bar', 210, 20, 22, 7, ''],
    ['Beef jerky', '1 oz', 115, 9, 3, 7, 'jerky'],
    ['Deli turkey', '4 slices', 90, 16, 2, 1.5, ''],
    ['Cottage cheese', '1 cup', 220, 25, 8, 10, ''],
    ['Black beans', '1 cup', 227, 15, 41, 1, 'beans'],
    ['Lentils (cooked)', '1 cup', 230, 18, 40, 0.8, 'lentil'],
  ],
  'Fast food & mains': [
    ['Cheese pizza', '1 slice (large)', 285, 12, 36, 10, 'pizza'],
    ['Pepperoni pizza', '1 slice (large)', 310, 13, 35, 13, 'pizza'],
    ['Hamburger', '1 burger', 540, 30, 40, 29, 'burger'],
    ['Cheeseburger', '1 burger', 600, 32, 40, 34, 'burger'],
    ['Double cheeseburger', '1 burger', 800, 48, 42, 48, ''],
    ['Veggie burger', '1 burger', 420, 20, 45, 17, ''],
    ['Hot dog', '1 hot dog', 290, 11, 24, 17, ''],
    ['Burrito', '1 burrito', 750, 35, 85, 28, ''],
    ['Burrito bowl', '1 bowl', 650, 40, 70, 22, 'chipotle bowl'],
    ['Taco', '1 taco', 210, 10, 20, 10, 'tacos'],
    ['Quesadilla', '1 quesadilla', 520, 25, 40, 28, ''],
    ['Nachos', '1 plate', 800, 25, 75, 45, ''],
    ['Chicken sandwich', '1 sandwich', 520, 30, 48, 22, ''],
    ['Fried chicken sandwich', '1 sandwich', 650, 30, 55, 34, ''],
    ['Club sandwich', '1 sandwich', 590, 32, 45, 30, ''],
    ['Turkey sandwich', '1 sandwich', 380, 25, 40, 12, ''],
    ['Grilled cheese', '1 sandwich', 440, 15, 30, 28, ''],
    ['BLT', '1 sandwich', 450, 15, 30, 30, ''],
    ['Peanut butter and jelly sandwich', '1 sandwich', 380, 12, 50, 16, 'pb&j'],
    ['Philly cheesesteak', '1 sandwich', 800, 45, 60, 40, 'cheesesteak'],
    ['Sub sandwich (6 inch)', '6 inch', 450, 25, 45, 18, 'subway'],
    ['Wrap (chicken)', '1 wrap', 520, 32, 45, 22, ''],
    ['Gyro', '1 gyro', 600, 30, 50, 30, 'shawarma doner kebab'],
    ['Falafel wrap', '1 wrap', 560, 18, 70, 24, 'falafel'],
    ['Spaghetti with meat sauce', '1 plate', 650, 30, 80, 22, 'spaghetti bolognese'],
    ['Spaghetti with marinara', '1 plate', 450, 14, 82, 8, 'spaghetti'],
    ['Mac and cheese', '1 cup', 500, 18, 50, 25, 'macaroni and cheese'],
    ['Lasagna', '1 piece', 600, 33, 45, 32, ''],
    ['Fettuccine Alfredo', '1 plate', 900, 25, 85, 50, 'alfredo'],
    ['Chicken parmesan', '1 plate', 850, 55, 70, 38, 'chicken parmigiana'],
    ['Chicken stir fry', '1 plate', 450, 35, 35, 18, 'stir-fry'],
    ['Chicken curry with rice', '1 plate', 700, 35, 80, 25, 'curry'],
    ['Butter chicken', '1 cup', 490, 30, 14, 35, 'chicken tikka masala'],
    ['Pad thai', '1 plate', 750, 28, 95, 28, ''],
    ['Ramen', '1 bowl', 550, 22, 70, 20, ''],
    ['Pho', '1 bowl', 450, 30, 55, 10, ''],
    ['Sushi roll', '8 pieces', 350, 12, 55, 8, 'sushi maki'],
    ['Sashimi', '8 pieces', 250, 40, 0, 8, ''],
    ['Poke bowl', '1 bowl', 600, 35, 70, 18, ''],
    ['General Tso\'s chicken', '1 cup', 600, 25, 55, 30, 'orange chicken'],
    ['Lo mein', '1 plate', 550, 20, 75, 18, 'chow mein noodles'],
    ['Dumplings', '6 dumplings', 380, 16, 42, 16, 'gyoza potstickers'],
    ['Spring rolls', '2 rolls', 300, 6, 30, 18, 'egg roll'],
    ['Biryani', '1 plate', 650, 28, 80, 22, ''],
    ['Chili con carne', '1 bowl', 350, 25, 30, 14, 'chili'],
    ['Beef stew', '1 bowl', 400, 30, 30, 18, 'stew'],
    ['Meatloaf', '1 slice', 350, 25, 15, 21, ''],
    ['Shepherd\'s pie', '1 serving', 500, 25, 40, 26, 'cottage pie'],
    ['Roast dinner', '1 plate', 750, 45, 60, 35, 'sunday roast'],
    ['Kebab plate', '1 plate', 700, 45, 60, 30, 'kabob'],
    ['Paella', '1 plate', 600, 30, 70, 20, ''],
    ['Risotto', '1 cup', 450, 12, 60, 17, ''],
    ['Fajitas', '2 fajitas', 600, 35, 50, 28, ''],
    ['Enchiladas', '2 enchiladas', 600, 30, 50, 30, 'enchilada'],
    ['Corn dog', '1 corn dog', 250, 8, 25, 13, ''],
    ['Poutine', '1 serving', 740, 22, 75, 40, ''],
  ],
  'Soups': [
    ['Chicken noodle soup', '1 bowl', 160, 12, 18, 4, 'soup'],
    ['Tomato soup', '1 bowl', 180, 4, 30, 5, ''],
    ['Clam chowder', '1 bowl', 330, 12, 25, 20, 'chowder'],
    ['Miso soup', '1 bowl', 60, 4, 8, 2, ''],
    ['Lentil soup', '1 bowl', 280, 18, 40, 5, ''],
    ['Minestrone', '1 bowl', 200, 8, 32, 5, ''],
  ],
  'Snacks': [
    ['Almonds', '1 oz (23 nuts)', 165, 6, 6, 14, 'nuts'],
    ['Peanuts', '1 oz', 166, 7, 6, 14, ''],
    ['Mixed nuts', '1/4 cup', 200, 6, 7, 18, 'trail mix'],
    ['Peanut butter', '2 tbsp', 190, 7, 7, 16, ''],
    ['Potato chips', '1 oz bag', 155, 2, 15, 10, 'crisps'],
    ['Tortilla chips & salsa', '1 basket', 400, 5, 50, 20, ''],
    ['Popcorn (air-popped)', '3 cups', 93, 3, 19, 1, ''],
    ['Movie popcorn (buttered)', 'medium', 600, 8, 60, 38, ''],
    ['Pretzels', '1 oz', 110, 3, 23, 1, ''],
    ['Crackers', '10 crackers', 140, 2, 20, 6, ''],
    ['Cheese stick', '1 stick', 80, 7, 1, 6, 'string cheese'],
    ['Cheddar cheese', '1 oz slice', 115, 7, 0.4, 9, 'cheese'],
    ['Granola bar', '1 bar', 190, 4, 29, 7, ''],
    ['Rice cakes', '2 cakes', 70, 1.5, 15, 0.5, ''],
    ['Hard-boiled eggs (2)', '2 eggs', 156, 12, 1, 10, ''],
  ],
  'Desserts & sweets': [
    ['Chocolate chip cookie', '1 large', 220, 2.5, 30, 11, 'cookie'],
    ['Brownie', '1 square', 230, 3, 30, 12, 'chocolate brownie'],
    ['Donut (glazed)', '1 donut', 260, 3, 31, 14, 'doughnut'],
    ['Muffin (blueberry)', '1 large', 430, 6, 60, 19, 'muffin'],
    ['Cupcake', '1 frosted', 300, 3, 45, 13, ''],
    ['Cheesecake', '1 slice', 400, 7, 32, 28, ''],
    ['Chocolate cake', '1 slice', 420, 5, 55, 21, 'cake'],
    ['Apple pie', '1 slice', 410, 4, 58, 19, 'pie'],
    ['Ice cream', '1 cup', 275, 5, 32, 15, ''],
    ['Frozen yogurt', '1 cup', 220, 6, 40, 4, 'froyo'],
    ['Milkshake', '16 oz', 700, 15, 100, 25, 'shake'],
    ['Chocolate bar', '1 bar (45 g)', 235, 3, 26, 13, 'candy bar'],
    ['Gummy candy', '1 small bag', 140, 2, 33, 0, 'gummies'],
    ['Cinnamon roll', '1 roll', 420, 6, 60, 18, ''],
    ['Tiramisu', '1 piece', 450, 8, 40, 28, ''],
    ['Churros', '2 churros', 240, 3, 28, 13, 'churro'],
  ],
  'Drinks': [
    ['Black coffee', '1 cup', 2, 0.3, 0, 0, 'coffee americano'],
    ['Latte', '16 oz', 190, 13, 19, 7, 'cappuccino flat white'],
    ['Iced coffee with cream & sugar', '16 oz', 160, 2, 25, 6, ''],
    ['Frappuccino', '16 oz', 380, 5, 54, 15, 'frappe'],
    ['Orange juice', '12 oz', 165, 2.5, 39, 0.7, 'juice'],
    ['Soda', '12 oz can', 150, 0, 39, 0, 'coke cola pop soft drink'],
    ['Diet soda', '12 oz can', 0, 0, 0, 0, 'diet coke zero'],
    ['Energy drink', '16 oz can', 220, 0, 54, 0, 'red bull monster'],
    ['Sports drink', '20 oz', 140, 0, 36, 0, 'gatorade'],
    ['Smoothie (fruit)', '16 oz', 300, 4, 70, 1, 'smoothie'],
    ['Whole milk', '1 cup', 150, 8, 12, 8, 'milk'],
    ['Skim milk', '1 cup', 85, 8, 12, 0.2, ''],
    ['Chocolate milk', '1 cup', 210, 8, 26, 8, ''],
    ['Beer', '12 oz', 155, 1.6, 13, 0, 'lager'],
    ['Light beer', '12 oz', 105, 1, 6, 0, ''],
    ['Wine', '5 oz glass', 125, 0.1, 4, 0, 'red wine white wine'],
    ['Bubble tea', '16 oz', 350, 2, 70, 7, 'boba milk tea'],
  ],
};

let nextId = 0;
export const FOODS = Object.entries(RAW).flatMap(([category, rows]) =>
  rows.map(([name, serving, calories, protein, carbs, fat, aliases]) => ({
    id: `f${nextId++}`,
    name,
    serving,
    calories,
    protein,
    carbs,
    fat,
    category,
    aliases: aliases ? aliases.split(' ') : [],
  })),
);

export const FOOD_CATEGORIES = Object.keys(RAW);

export function normalize(s) {
  return s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9& ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const tokens = (s) => normalize(s).split(' ').filter((t) => t.length > 1);

// Text search over names + aliases, ranked by how well the query tokens match.
export function searchFoods(query, list = FOODS, limit = 30) {
  const q = tokens(query);
  if (!q.length) return [];
  const scored = [];
  for (const f of list) {
    const name = normalize(f.name);
    const hay = `${name} ${f.aliases.join(' ')}`;
    let score = 0;
    for (const t of q) {
      if (name.startsWith(t)) score += 4;
      else if (new RegExp(`\\b${t}`).test(name)) score += 3;
      else if (new RegExp(`\\b${t}`).test(hay)) score += 2;
      else if (hay.includes(t)) score += 1;
      else score -= 2;
    }
    if (score > 0) scored.push({ f, score: score - name.length / 100 });
  }
  return scored.sort((a, b) => b.score - a.score).slice(0, limit).map((s) => s.f);
}

// Rough per-serving estimates for dishes the database doesn't know, by keyword.
const DISH_KEYWORDS = [
  [['salad'], { calories: 300, protein: 10, carbs: 18, fat: 20, serving: '1 bowl' }],
  [['soup', 'broth', 'chowder', 'bisque'], { calories: 250, protein: 12, carbs: 25, fat: 10, serving: '1 bowl' }],
  [['stew', 'curry', 'masala', 'korma', 'goulash', 'tagine'], { calories: 450, protein: 25, carbs: 30, fat: 24, serving: '1 bowl' }],
  [['pizza'], { calories: 300, protein: 12, carbs: 35, fat: 12, serving: '1 slice' }],
  [['burger'], { calories: 600, protein: 30, carbs: 42, fat: 32, serving: '1 burger' }],
  [['sandwich', 'sub', 'panini', 'roll', 'banh mi', 'hoagie'], { calories: 500, protein: 24, carbs: 48, fat: 22, serving: '1 sandwich' }],
  [['taco', 'burrito', 'enchilada', 'tamale', 'quesadilla'], { calories: 450, protein: 20, carbs: 45, fat: 20, serving: '1 serving' }],
  [['noodle', 'ramen', 'udon', 'soba', 'pho', 'mein', 'pasta', 'spaghetti', 'linguine', 'penne', 'macaroni', 'ravioli', 'gnocchi', 'lasagna'], { calories: 600, protein: 22, carbs: 80, fat: 20, serving: '1 plate' }],
  [['rice', 'pilaf', 'biryani', 'risotto', 'paella'], { calories: 550, protein: 18, carbs: 80, fat: 16, serving: '1 plate' }],
  [['cake', 'torte', 'gateau'], { calories: 400, protein: 5, carbs: 52, fat: 19, serving: '1 slice' }],
  [['pie', 'tart', 'strudel', 'cobbler', 'crumble'], { calories: 380, protein: 4, carbs: 50, fat: 18, serving: '1 slice' }],
  [['cookie', 'biscuit', 'macaron'], { calories: 150, protein: 2, carbs: 20, fat: 7, serving: '2 pieces' }],
  [['pudding', 'custard', 'mousse', 'flan', 'cotta'], { calories: 300, protein: 6, carbs: 40, fat: 13, serving: '1 cup' }],
  [['ice cream', 'gelato', 'sorbet', 'sundae', 'split'], { calories: 350, protein: 5, carbs: 45, fat: 17, serving: '1 cup' }],
  [['bread', 'bun', 'loaf', 'naan', 'flatbread', 'pita', 'roti', 'paratha'], { calories: 250, protein: 8, carbs: 45, fat: 5, serving: '1 piece' }],
  [['dumpling', 'bao', 'gyoza', 'pierogi', 'momo', 'empanada', 'samosa', 'pastry', 'pastel'], { calories: 400, protein: 14, carbs: 45, fat: 18, serving: '1 serving' }],
  [['fried', 'fritter', 'tempura', 'katsu', 'schnitzel'], { calories: 550, protein: 25, carbs: 35, fat: 34, serving: '1 plate' }],
  [['chicken', 'turkey', 'duck', 'poultry'], { calories: 450, protein: 40, carbs: 15, fat: 24, serving: '1 plate' }],
  [['beef', 'steak', 'pork', 'lamb', 'mutton', 'veal', 'ribs', 'brisket', 'sausage', 'ham'], { calories: 550, protein: 40, carbs: 12, fat: 36, serving: '1 plate' }],
  [['fish', 'salmon', 'tuna', 'cod', 'shrimp', 'prawn', 'crab', 'lobster', 'clam', 'mussel', 'oyster', 'squid', 'octopus', 'herring', 'seafood'], { calories: 380, protein: 35, carbs: 15, fat: 18, serving: '1 plate' }],
  [['egg', 'omelette', 'frittata', 'quiche'], { calories: 320, protein: 18, carbs: 8, fat: 24, serving: '1 serving' }],
  [['tofu', 'tempeh', 'bean', 'lentil', 'dal', 'chickpea', 'hummus', 'falafel'], { calories: 350, protein: 18, carbs: 40, fat: 12, serving: '1 bowl' }],
  [['cheese'], { calories: 400, protein: 20, carbs: 20, fat: 28, serving: '1 serving' }],
  [['potato', 'fries', 'chips'], { calories: 350, protein: 5, carbs: 45, fat: 17, serving: '1 serving' }],
  [['vegetable', 'veggie', 'greens', 'cabbage', 'spinach', 'eggplant', 'zucchini', 'mushroom'], { calories: 180, protein: 6, carbs: 20, fat: 9, serving: '1 cup' }],
  [['candy', 'fudge', 'toffee', 'brittle', 'halva', 'chocolate', 'sweet'], { calories: 250, protein: 3, carbs: 35, fat: 12, serving: '1 serving' }],
  [['drink', 'tea', 'coffee', 'juice', 'lassi', 'smoothie', 'shake', 'cocktail'], { calories: 200, protein: 3, carbs: 35, fat: 5, serving: '1 glass' }],
];

const GENERIC_DISH = { calories: 450, protein: 20, carbs: 45, fat: 20, serving: '1 plate' };

// Maps a recognised dish label to a database entry (exact/alias/token match) or a keyword estimate.
export function foodForLabel(label) {
  const norm = normalize(label);
  if (!norm) return null;
  const words = norm.split(' ');
  let best = null;
  let bestScore = 0;
  for (const f of FOODS) {
    const name = normalize(f.name.replace(/\(.*?\)/g, ''));
    if (name === norm) return { food: f, exact: true };
    let score = 0;
    if (norm.includes(name)) score = name.length * 2;
    for (const a of f.aliases) if (a.length > 2 && words.includes(a)) score = Math.max(score, a.length * 1.5);
    const nameWords = name.split(' ').filter((w) => w.length > 2);
    if (nameWords.length && nameWords.every((w) => words.includes(w))) score = Math.max(score, name.length * 1.8);
    if (score > bestScore) {
      bestScore = score;
      best = f;
    }
  }
  if (best && bestScore >= 8) return { food: best, exact: false };
  for (const [keys, est] of DISH_KEYWORDS) {
    if (keys.some((k) => norm.includes(k))) return { food: { id: `est:${norm}`, name: label, category: 'Estimated', aliases: [], ...est }, estimated: true };
  }
  return { food: { id: `est:${norm}`, name: label, category: 'Estimated', aliases: [], ...GENERIC_DISH }, estimated: true };
}
