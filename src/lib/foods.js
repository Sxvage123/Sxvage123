// Built-in nutrition database (typical USDA values per common serving), plus helpers to map
// on-device food-recognition labels to entries. Format: [name, serving, kcal, protein, carbs, fat, aliases]

const RAW = {
  Breakfast: [
    ['Scrambled eggs', '2 large eggs', 182, 12, 2, 14, 'scrambled egg, egg'],
    ['Fried egg', '1 large egg', 90, 6, 0.4, 7, 'sunny side up, egg'],
    ['Boiled egg', '1 large egg', 78, 6, 0.6, 5, 'hard boiled egg, egg, eggs'],
    ['Omelette (3 egg, cheese)', '1 omelette', 400, 25, 3, 31, 'omelet, omelette'],
    ['Egg whites', '1 cup', 126, 26, 2, 0.4, 'egg white'],
    ['Pancakes with syrup', '3 pancakes', 520, 10, 90, 14, 'pancake, hotcake, flapjack'],
    ['Waffle', '1 large waffle', 310, 8, 38, 14, 'waffles'],
    ['French toast', '2 slices', 360, 12, 40, 16, ''],
    ['Oatmeal (cooked)', '1 cup', 166, 6, 28, 4, 'porridge, oats, oatmeal'],
    ['Overnight oats', '1 jar', 350, 14, 52, 10, ''],
    ['Granola', '1/2 cup', 300, 7, 37, 15, ''],
    ['Cereal with milk', '1 bowl', 250, 8, 42, 5, 'cereal, cornflakes, cheerios'],
    ['Greek yogurt (plain, nonfat)', '170 g cup', 100, 17, 6, 0.7, 'yogurt, yoghurt, greek yogurt'],
    ['Greek yogurt (flavored)', '150 g cup', 140, 12, 18, 2.5, 'flavored yogurt, fruit yogurt'],
    ['Yogurt parfait', '1 cup', 280, 10, 45, 7, 'parfait'],
    ['Bagel with cream cheese', '1 bagel', 390, 12, 58, 12, 'bagel, cream cheese bagel'],
    ['Plain bagel', '1 bagel', 270, 11, 53, 1.5, ''],
    ['Croissant', '1 croissant', 270, 5, 31, 14, ''],
    ['Breakfast burrito', '1 burrito', 550, 25, 45, 29, 'breakfast burrito'],
    ['Breakfast sandwich (egg, cheese, bacon)', '1 sandwich', 450, 20, 33, 26, 'egg mcmuffin, breakfast sandwich, egg sandwich'],
    ['Bacon', '3 strips', 130, 9, 0.4, 10, ''],
    ['Sausage links', '2 links', 170, 8, 1, 15, 'breakfast sausage, sausage'],
    ['Hash browns', '1 cup', 320, 3, 35, 19, 'hash brown, hashbrown, rosti, rösti'],
    ['Avocado toast', '1 slice', 260, 6, 26, 15, ''],
    ['Toast with butter', '1 slice', 120, 3, 14, 6, 'toast, buttered toast'],
    ['Peanut butter toast', '1 slice', 280, 10, 22, 17, ''],
    ['Eggs Benedict', '2 halves', 700, 30, 32, 50, ''],
    ['Chia pudding', '1 cup', 280, 8, 30, 15, ''],
    ['Acai bowl', '1 bowl', 500, 7, 85, 15, 'açaí bowl, acai'],
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
    ['Fruit salad', '1 cup', 90, 1, 23, 0.3, 'fruit cup, fruit salad'],
    ['Raisins', '1/4 cup', 120, 1, 32, 0.2, ''],
    ['Kiwi', '1 fruit', 42, 0.8, 10, 0.4, ''],
    ['Cherries', '1 cup', 87, 1.5, 22, 0.3, 'cherry'],
    ['Lemon', '1 fruit', 17, 0.6, 5, 0.2, 'lime'],
    ['Figs', '2 medium', 74, 0.8, 19, 0.3, 'fig'],
    ['Pomegranate seeds', '1/2 cup', 72, 1.5, 16, 1, 'pomegranate'],
    ['Jackfruit', '1 cup', 157, 2.8, 38, 1, ''],
  ],
  'Vegetables & sides': [
    ['Garden salad (no dressing)', '2 cups', 35, 2, 7, 0.3, 'green salad, salad, garden salad'],
    ['Caesar salad', '1 bowl', 360, 10, 14, 30, 'caesar'],
    ['Greek salad', '1 bowl', 250, 6, 12, 20, 'horiatiki'],
    ['Chicken salad (grilled)', '1 bowl', 380, 35, 12, 20, 'cobb salad, chicken salad'],
    ['Potato salad', '1 cup', 360, 7, 28, 21, ''],
    ['Coleslaw', '1 cup', 290, 2, 15, 25, ''],
    ['Steamed broccoli', '1 cup', 55, 4, 11, 0.6, 'broccoli'],
    ['Mixed vegetables', '1 cup', 80, 4, 16, 0.5, 'veggies, mixed vegetable'],
    ['Roasted vegetables', '1 cup', 140, 3, 16, 7, 'roast vegetable, grilled vegetable'],
    ['Green beans', '1 cup', 44, 2, 10, 0.4, ''],
    ['Corn on the cob', '1 ear', 90, 3, 19, 1.4, 'corn, elote, sweet corn'],
    ['Baked potato (plain)', '1 medium', 160, 4, 37, 0.2, 'potato, jacket potato'],
    ['Loaded baked potato', '1 potato', 450, 13, 50, 22, 'potato skins, loaded potato'],
    ['Mashed potatoes', '1 cup', 240, 4, 35, 9, 'mashed potato, mash, colcannon, stoemp'],
    ['Sweet potato', '1 medium', 112, 2, 26, 0.1, ''],
    ['French fries', 'medium serving', 365, 4, 48, 17, 'fries, chips, frites, pommes frites'],
    ['Sweet potato fries', 'medium serving', 380, 3, 50, 18, 'sweet potato fry'],
    ['Onion rings', '8 rings', 330, 4, 37, 19, 'onion ring'],
    ['Side salad with dressing', '1 bowl', 150, 2, 8, 12, ''],
    ['Hummus', '1/4 cup', 100, 5, 9, 6, ''],
    ['Guacamole', '1/4 cup', 110, 1, 6, 10, ''],
    ['Edamame', '1 cup', 190, 17, 15, 8, ''],
    ['Spinach (cooked)', '1 cup', 41, 5, 7, 0.5, 'spinach'],
    ['Carrots', '1 cup', 52, 1.2, 12, 0.3, 'carrot'],
    ['Cucumber', '1 cup', 16, 0.7, 4, 0.1, ''],
    ['Bell pepper', '1 medium', 31, 1, 7, 0.3, 'pepper, capsicum'],
    ['Mushrooms (sautéed)', '1 cup', 80, 3, 5, 6, 'mushroom'],
    ['Zucchini', '1 cup', 20, 1.5, 4, 0.4, 'courgette'],
    ['Cauliflower', '1 cup', 27, 2, 5, 0.3, ''],
    ['Cabbage', '1 cup', 22, 1.1, 5, 0.1, ''],
    ['Squash (roasted)', '1 cup', 82, 1.8, 22, 0.2, 'butternut squash, acorn squash, spaghetti squash, pumpkin'],
    ['Artichoke', '1 medium', 64, 3.5, 14, 0.4, ''],
  ],
  'Grains & bread': [
    ['White rice (cooked)', '1 cup', 205, 4, 45, 0.4, 'rice, steamed rice, white rice'],
    ['Brown rice (cooked)', '1 cup', 216, 5, 45, 1.8, ''],
    ['Fried rice', '1 cup', 330, 8, 45, 13, 'fried rice, chahan, nasi goreng, chaufa'],
    ['Quinoa (cooked)', '1 cup', 222, 8, 39, 3.6, ''],
    ['Pasta (cooked, plain)', '1 cup', 220, 8, 43, 1.3, 'pasta, noodle'],
    ['White bread', '1 slice', 75, 2.6, 14, 1, 'bread'],
    ['Whole wheat bread', '1 slice', 80, 4, 14, 1, ''],
    ['Tortilla (flour)', '1 large', 210, 6, 35, 5, 'tortilla'],
    ['Garlic bread', '1 slice', 170, 4, 20, 8, ''],
    ['Dinner roll', '1 roll', 110, 3, 19, 2, 'roll, bun, bread roll'],
    ['Cornbread', '1 piece', 200, 4, 30, 7, ''],
    ['Naan', '1 piece', 260, 9, 45, 5, 'naan, nan bread'],
    ['Pita bread', '1 pita', 165, 5, 33, 0.7, 'pita, pitta'],
    ['Couscous', '1 cup', 176, 6, 36, 0.3, ''],
  ],
  'Meat, fish & protein': [
    ['Grilled chicken breast', '6 oz (170 g)', 280, 53, 0, 6, 'chicken breast, grilled chicken, chicken'],
    ['Chicken thigh (roasted)', '2 thighs', 360, 38, 0, 22, 'chicken thigh'],
    ['Rotisserie chicken', '1/4 chicken', 400, 45, 0, 24, 'roast chicken, rotisserie chicken'],
    ['Fried chicken', '2 pieces', 560, 40, 18, 36, 'fried chicken, crispy fried chicken, karaage'],
    ['Chicken wings', '6 wings', 480, 36, 4, 34, 'buffalo wing, chicken wing, wing'],
    ['Chicken nuggets', '10 pieces', 450, 24, 27, 28, 'nugget, chicken nugget'],
    ['Chicken tenders', '4 tenders', 480, 32, 28, 26, 'chicken strip, chicken finger, tender'],
    ['Steak (sirloin)', '8 oz (225 g)', 460, 62, 0, 22, 'steak, beef steak, sirloin'],
    ['Ribeye steak', '10 oz (280 g)', 790, 66, 0, 58, 'ribeye, rib eye'],
    ['Ground beef (80/20, cooked)', '4 oz', 290, 20, 0, 23, 'ground beef, mince'],
    ['Ground turkey (cooked)', '4 oz', 230, 27, 0, 13, 'ground turkey'],
    ['Pork chop', '1 chop', 280, 35, 0, 15, 'pork chop, tonkatsu'],
    ['Pulled pork', '1 cup', 420, 36, 10, 26, 'pulled pork, carnitas'],
    ['BBQ ribs', '1/2 rack', 800, 55, 20, 55, 'ribs, spare ribs, rib'],
    ['Meatballs', '4 meatballs', 320, 20, 10, 22, 'meatball, kofta, köttbullar, frikadeller'],
    ['Salmon fillet', '6 oz (170 g)', 350, 38, 0, 21, 'salmon'],
    ['Tuna (canned in water)', '1 can', 120, 26, 0, 1, 'tuna'],
    ['Shrimp (cooked)', '6 oz', 170, 36, 0, 2, 'shrimp, prawn, scampi'],
    ['Fish and chips', '1 plate', 900, 35, 90, 45, 'fish and chip'],
    ['White fish (baked)', '6 oz', 180, 38, 0, 2, 'cod, tilapia, white fish, fish'],
    ['Tofu (firm)', '1/2 block', 180, 20, 4, 11, 'tofu, bean curd'],
    ['Protein shake', '1 scoop + water', 120, 24, 3, 1.5, 'whey shake, protein shake'],
    ['Protein shake with milk', '1 scoop + milk', 250, 32, 15, 6, 'protein milkshake'],
    ['Protein bar', '1 bar', 210, 20, 22, 7, 'protein bar'],
    ['Beef jerky', '1 oz', 115, 9, 3, 7, 'jerky'],
    ['Deli turkey', '4 slices', 90, 16, 2, 1.5, 'turkey slices'],
    ['Cottage cheese', '1 cup', 220, 25, 8, 10, 'cottage cheese, quark'],
    ['Black beans', '1 cup', 227, 15, 41, 1, 'beans, black bean'],
    ['Lentils (cooked)', '1 cup', 230, 18, 40, 0.8, 'lentil, dal, dhal, daal'],
  ],
  'Fast food & mains': [
    ['Cheese pizza', '1 slice (large)', 285, 12, 36, 10, 'pizza, margherita, neapolitan pizza'],
    ['Pepperoni pizza', '1 slice (large)', 310, 13, 35, 13, 'pepperoni, pepperoni pizza'],
    ['Hamburger', '1 burger', 540, 30, 40, 29, 'burger, hamburger'],
    ['Cheeseburger', '1 burger', 600, 32, 40, 34, 'cheeseburger, cheese burger'],
    ['Double cheeseburger', '1 burger', 800, 48, 42, 48, 'double cheeseburger'],
    ['Veggie burger', '1 burger', 420, 20, 45, 17, 'veggie burger'],
    ['Hot dog', '1 hot dog', 290, 11, 24, 17, 'hot dog, hotdog, frankfurter, chili dog, corn dog'],
    ['Burrito', '1 burrito', 750, 35, 85, 28, 'burrito'],
    ['Burrito bowl', '1 bowl', 650, 40, 70, 22, 'chipotle bowl, burrito bowl'],
    ['Taco', '1 taco', 210, 10, 20, 10, 'taco'],
    ['Quesadilla', '1 quesadilla', 520, 25, 40, 28, 'quesadilla, sincronizada'],
    ['Nachos', '1 plate', 800, 25, 75, 45, 'nacho'],
    ['Chicken sandwich', '1 sandwich', 520, 30, 48, 22, 'chicken sandwich'],
    ['Fried chicken sandwich', '1 sandwich', 650, 30, 55, 34, 'crispy chicken sandwich'],
    ['Club sandwich', '1 sandwich', 590, 32, 45, 30, 'club sandwich'],
    ['Turkey sandwich', '1 sandwich', 380, 25, 40, 12, 'turkey sandwich, sandwich'],
    ['Grilled cheese', '1 sandwich', 440, 15, 30, 28, 'grilled cheese, cheese sandwich, toastie'],
    ['BLT', '1 sandwich', 450, 15, 30, 30, 'blt'],
    ['Peanut butter and jelly sandwich', '1 sandwich', 380, 12, 50, 16, 'pb&j, pbj, peanut butter sandwich'],
    ['Philly cheesesteak', '1 sandwich', 800, 45, 60, 40, 'cheesesteak, philly'],
    ['Sub sandwich (6 inch)', '6 inch', 450, 25, 45, 18, 'sub, subway, hoagie, hero, submarine sandwich'],
    ['Wrap (chicken)', '1 wrap', 520, 32, 45, 22, 'wrap, chicken wrap'],
    ['Gyro', '1 gyro', 600, 30, 50, 30, 'gyro, gyros, shawarma, doner, döner, kebab'],
    ['Falafel wrap', '1 wrap', 560, 18, 70, 24, 'falafel'],
    ['Spaghetti with meat sauce', '1 plate', 650, 30, 80, 22, 'spaghetti bolognese, bolognese, spaghetti'],
    ['Spaghetti with marinara', '1 plate', 450, 14, 82, 8, 'marinara, pasta pomodoro, aglio e olio'],
    ['Mac and cheese', '1 cup', 500, 18, 50, 25, 'macaroni and cheese, macaroni, mac n cheese'],
    ['Lasagna', '1 piece', 600, 33, 45, 32, 'lasagne, lasagna'],
    ['Fettuccine Alfredo', '1 plate', 900, 25, 85, 50, 'alfredo, carbonara'],
    ['Chicken parmesan', '1 plate', 850, 55, 70, 38, 'chicken parmigiana, parmigiana, chicken parm'],
    ['Chicken stir fry', '1 plate', 450, 35, 35, 18, 'stir fry, stir-fry'],
    ['Chicken curry with rice', '1 plate', 700, 35, 80, 25, 'curry, chicken curry, curry rice'],
    ['Butter chicken', '1 cup', 490, 30, 14, 35, 'butter chicken, chicken tikka masala, tikka masala'],
    ['Pad thai', '1 plate', 750, 28, 95, 28, 'pad thai, phat thai'],
    ['Ramen', '1 bowl', 550, 22, 70, 20, 'ramen'],
    ['Pho', '1 bowl', 450, 30, 55, 10, 'pho, phở'],
    ['Sushi roll', '8 pieces', 350, 12, 55, 8, 'sushi, maki, sushi roll, gimbap, kimbap'],
    ['Sashimi', '8 pieces', 250, 40, 0, 8, 'sashimi'],
    ['Poke bowl', '1 bowl', 600, 35, 70, 18, 'poke'],
    ['General Tso\'s chicken', '1 cup', 600, 25, 55, 30, 'orange chicken, general tso, sesame chicken, kung pao chicken'],
    ['Lo mein', '1 plate', 550, 20, 75, 18, 'lo mein, chow mein'],
    ['Dumplings', '6 dumplings', 380, 16, 42, 16, 'dumpling, gyoza, potsticker, jiaozi, mandu, momo, wonton'],
    ['Spring rolls', '2 rolls', 300, 6, 30, 18, 'spring roll, egg roll, chả giò, lumpia, popiah'],
    ['Biryani', '1 plate', 650, 28, 80, 22, 'biryani, biriyani'],
    ['Chili con carne', '1 bowl', 350, 25, 30, 14, 'chili, chilli, chili con carne'],
    ['Beef stew', '1 bowl', 400, 30, 30, 18, 'stew, beef stew, goulash'],
    ['Meatloaf', '1 slice', 350, 25, 15, 21, 'meatloaf'],
    ['Chicken pot pie', '1 pie', 650, 25, 55, 37, 'pot pie, potpie'],
    ['Shepherd\'s pie', '1 serving', 500, 25, 40, 26, 'cottage pie, shepherd pie'],
    ['Roast dinner', '1 plate', 750, 45, 60, 35, 'sunday roast, roast dinner'],
    ['Kebab plate', '1 plate', 700, 45, 60, 30, 'kabob, kebab plate'],
    ['Paella', '1 plate', 600, 30, 70, 20, 'paella'],
    ['Risotto', '1 cup', 450, 12, 60, 17, 'risotto'],
    ['Fajitas', '2 fajitas', 600, 35, 50, 28, 'fajita'],
    ['Enchiladas', '2 enchiladas', 600, 30, 50, 30, 'enchilada'],
    ['Corn dog', '1 corn dog', 250, 8, 25, 13, 'corn dog'],
    ['Poutine', '1 serving', 740, 22, 75, 40, 'poutine'],
  ],
  'Restaurant favorites': [
    ['Big Mac', '1 burger', 590, 25, 46, 34, 'big mac, mcdonalds burger'],
    ['McChicken', '1 sandwich', 400, 14, 39, 21, 'mcchicken'],
    ['Quarter Pounder with Cheese', '1 burger', 520, 30, 42, 26, 'quarter pounder'],
    ['McDonald’s fries (medium)', 'medium', 320, 5, 43, 15, 'mcdonalds fries'],
    ['Chicken McNuggets (10 pc)', '10 pieces', 410, 23, 25, 24, 'mcnuggets'],
    ['Egg McMuffin', '1 sandwich', 310, 17, 30, 13, 'mcmuffin'],
    ['Chick-fil-A Chicken Sandwich', '1 sandwich', 420, 29, 41, 18, 'chick fil a sandwich, chickfila'],
    ['Chick-fil-A Nuggets (8 ct)', '8 pieces', 250, 27, 11, 11, 'chick fil a nuggets'],
    ['Chick-fil-A Waffle Fries (medium)', 'medium', 420, 5, 45, 24, 'waffle fries'],
    ['Chipotle chicken burrito', '1 burrito', 1000, 55, 110, 37, 'chipotle burrito'],
    ['Chipotle chicken bowl', '1 bowl', 660, 50, 60, 23, 'chipotle bowl'],
    ['Taco Bell Crunchwrap Supreme', '1 wrap', 530, 16, 71, 21, 'crunchwrap'],
    ['Taco Bell Crunchy Taco', '1 taco', 170, 8, 13, 10, 'crunchy taco'],
    ['Subway 6" turkey sub', '6 inch', 280, 18, 46, 4, 'subway turkey'],
    ['Wendy’s Dave’s Single', '1 burger', 590, 29, 39, 34, 'daves single'],
    ['Five Guys cheeseburger', '1 burger', 980, 47, 40, 69, 'five guys'],
    ['In-N-Out Double-Double', '1 burger', 610, 37, 39, 34, 'double double, in n out'],
    ['Popeyes chicken sandwich', '1 sandwich', 700, 28, 50, 42, 'popeyes'],
    ['KFC Original Recipe breast', '1 piece', 390, 39, 11, 21, 'kfc'],
    ['Domino’s pepperoni pizza (large slice)', '1 slice', 300, 12, 31, 14, 'dominos'],
    ['Panda Express orange chicken', '1 entree', 490, 25, 51, 21, 'panda express'],
    ['Starbucks grande caramel macchiato', '16 oz', 250, 10, 35, 7, 'caramel macchiato'],
    ['Dunkin’ glazed donut', '1 donut', 240, 4, 33, 11, 'dunkin donut'],
  ],
  'Gym & meal prep': [
    ['Chicken, rice & broccoli', '1 container', 520, 48, 55, 9, 'meal prep, chicken and rice'],
    ['Steak & eggs', '1 plate', 620, 55, 2, 42, 'steak and eggs'],
    ['Protein pancakes', '3 pancakes', 350, 30, 40, 7, 'protein pancake'],
    ['Overnight protein oats', '1 jar', 420, 35, 50, 9, 'protein oats'],
    ['Greek yogurt & berries', '1 bowl', 220, 20, 28, 2, 'yogurt bowl'],
    ['Turkey & avocado wrap', '1 wrap', 450, 32, 38, 18, 'turkey wrap'],
    ['Salmon, sweet potato & greens', '1 plate', 560, 40, 42, 24, 'salmon meal prep'],
    ['Ground beef burrito bowl', '1 bowl', 680, 42, 62, 28, 'beef bowl'],
    ['Tuna salad (light mayo)', '1 cup', 280, 30, 4, 15, 'tuna salad'],
    ['Cottage cheese & pineapple', '1 bowl', 220, 25, 20, 4, 'cottage cheese bowl'],
    ['Instant ramen', '1 pack', 380, 8, 52, 14, 'cup noodles, instant noodles, maruchan'],
    ['Peanut butter banana smoothie', '16 oz', 450, 20, 55, 18, 'pb banana smoothie'],
    ['Casein shake', '1 scoop + water', 120, 24, 4, 1, 'casein'],
    ['Mass gainer shake', '1 serving', 650, 50, 85, 10, 'mass gainer, weight gainer'],
  ],
  'Soups': [
    ['Chicken noodle soup', '1 bowl', 160, 12, 18, 4, 'chicken soup, chicken noodle'],
    ['Tomato soup', '1 bowl', 180, 4, 30, 5, 'tomato soup'],
    ['Clam chowder', '1 bowl', 330, 12, 25, 20, 'chowder, clam chowder'],
    ['Miso soup', '1 bowl', 60, 4, 8, 2, 'miso soup, miso'],
    ['Lentil soup', '1 bowl', 280, 18, 40, 5, 'lentil soup, harira'],
    ['Minestrone', '1 bowl', 200, 8, 32, 5, 'minestrone'],
  ],
  'Snacks': [
    ['Almonds', '1 oz (23 nuts)', 165, 6, 6, 14, 'almond'],
    ['Peanuts', '1 oz', 166, 7, 6, 14, 'peanut'],
    ['Mixed nuts', '1/4 cup', 200, 6, 7, 18, 'nuts, trail mix'],
    ['Peanut butter', '2 tbsp', 190, 7, 7, 16, 'peanut butter'],
    ['Potato chips', '1 oz bag', 155, 2, 15, 10, 'crisps, potato chips'],
    ['Tortilla chips & salsa', '1 basket', 400, 5, 50, 20, 'tortilla chips, totopo, chips and salsa'],
    ['Popcorn (air-popped)', '3 cups', 93, 3, 19, 1, 'popcorn'],
    ['Movie popcorn (buttered)', 'medium', 600, 8, 60, 38, 'buttered popcorn'],
    ['Pretzels', '1 oz', 110, 3, 23, 1, 'pretzel'],
    ['Crackers', '10 crackers', 140, 2, 20, 6, 'cracker'],
    ['Cheese stick', '1 stick', 80, 7, 1, 6, 'string cheese, cheese stick, mozzarella stick'],
    ['Cheddar cheese', '1 oz slice', 115, 7, 0.4, 9, 'cheese, cheddar'],
    ['Granola bar', '1 bar', 190, 4, 29, 7, 'granola bar'],
    ['Rice cakes', '2 cakes', 70, 1.5, 15, 0.5, 'rice cake'],
    ['Hard-boiled eggs (2)', '2 eggs', 156, 12, 1, 10, 'hard boiled eggs'],
  ],
  'Desserts & sweets': [
    ['Chocolate chip cookie', '1 large', 220, 2.5, 30, 11, 'cookie, cookies, chocolate chip cookie'],
    ['Brownie', '1 square', 230, 3, 30, 12, 'brownie, chocolate brownie, blondie'],
    ['Donut (glazed)', '1 donut', 260, 3, 31, 14, 'donut, doughnut, glazed donut, berliner, beignet, pączki'],
    ['Muffin (blueberry)', '1 large', 430, 6, 60, 19, 'muffin'],
    ['Cupcake', '1 frosted', 300, 3, 45, 13, 'cupcake, fairy cake'],
    ['Cheesecake', '1 slice', 400, 7, 32, 28, 'cheesecake'],
    ['Chocolate cake', '1 slice', 420, 5, 55, 21, 'cake, chocolate cake'],
    ['Apple pie', '1 slice', 410, 4, 58, 19, 'apple pie, pie'],
    ['Ice cream', '1 cup', 275, 5, 32, 15, 'ice cream, gelato'],
    ['Frozen yogurt', '1 cup', 220, 6, 40, 4, 'froyo, frozen yogurt'],
    ['Milkshake', '16 oz', 700, 15, 100, 25, 'milkshake, shake'],
    ['Chocolate bar', '1 bar (45 g)', 235, 3, 26, 13, 'candy bar, chocolate'],
    ['Gummy candy', '1 small bag', 140, 2, 33, 0, 'gummies, gummy bears, candy'],
    ['Cinnamon roll', '1 roll', 420, 6, 60, 18, 'cinnamon roll, cinnamon bun'],
    ['Tiramisu', '1 piece', 450, 8, 40, 28, 'tiramisu'],
    ['Churros', '2 churros', 240, 3, 28, 13, 'churro'],
  ],
  'Drinks': [
    ['Black coffee', '1 cup', 2, 0.3, 0, 0, 'coffee, americano, espresso'],
    ['Latte', '16 oz', 190, 13, 19, 7, 'latte, cappuccino, flat white'],
    ['Iced coffee with cream & sugar', '16 oz', 160, 2, 25, 6, 'iced coffee'],
    ['Frappuccino', '16 oz', 380, 5, 54, 15, 'frappe, frappuccino'],
    ['Orange juice', '12 oz', 165, 2.5, 39, 0.7, 'juice, orange juice'],
    ['Soda', '12 oz can', 150, 0, 39, 0, 'coke, cola, soda, pop, soft drink'],
    ['Diet soda', '12 oz can', 0, 0, 0, 0, 'diet coke, coke zero, diet soda'],
    ['Energy drink', '16 oz can', 220, 0, 54, 0, 'red bull, monster, energy drink'],
    ['Sports drink', '20 oz', 140, 0, 36, 0, 'gatorade, powerade'],
    ['Smoothie (fruit)', '16 oz', 300, 4, 70, 1, 'smoothie'],
    ['Whole milk', '1 cup', 150, 8, 12, 8, 'milk'],
    ['Skim milk', '1 cup', 85, 8, 12, 0.2, 'skim milk'],
    ['Chocolate milk', '1 cup', 210, 8, 26, 8, 'chocolate milk'],
    ['Beer', '12 oz', 155, 1.6, 13, 0, 'beer, lager, ale'],
    ['Light beer', '12 oz', 105, 1, 6, 0, 'light beer'],
    ['Wine', '5 oz glass', 125, 0.1, 4, 0, 'wine, red wine, white wine'],
    ['Bubble tea', '16 oz', 350, 2, 70, 7, 'boba, bubble tea, milk tea'],
    ['Eggnog', '1 cup', 340, 10, 34, 19, ''],
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
    aliases: aliases ? aliases.split(',').map((a) => a.trim()).filter(Boolean) : [],
  })),
);

export const FOOD_CATEGORIES = Object.keys(RAW);

export function normalize(s) {
  return String(s)
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
    const hay = `${name} ${(f.aliases || []).map(normalize).join(' ')} ${normalize(f.brand || '')}`;
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

// ImageNet labels (general-purpose classifier) that are foods, mapped to database names.
export const IMAGENET_FOODS = {
  guacamole: 'Guacamole', consomme: 'Chicken noodle soup', 'hot pot': 'Beef stew', trifle: 'Tiramisu', 'ice cream': 'Ice cream',
  'French loaf': 'White bread', bagel: 'Plain bagel', pretzel: 'Pretzels', cheeseburger: 'Cheeseburger', hotdog: 'Hot dog',
  'mashed potato': 'Mashed potatoes', 'head cabbage': 'Cabbage', broccoli: 'Steamed broccoli', cauliflower: 'Cauliflower',
  zucchini: 'Zucchini', 'spaghetti squash': 'Squash (roasted)', 'acorn squash': 'Squash (roasted)', 'butternut squash': 'Squash (roasted)',
  cucumber: 'Cucumber', artichoke: 'Artichoke', 'bell pepper': 'Bell pepper', mushroom: 'Mushrooms (sautéed)', 'Granny Smith': 'Apple',
  strawberry: 'Strawberries', orange: 'Orange', lemon: 'Lemon', fig: 'Figs', pineapple: 'Pineapple', banana: 'Banana', jackfruit: 'Jackfruit',
  pomegranate: 'Pomegranate seeds', carbonara: 'Fettuccine Alfredo', 'meat loaf': 'Meatloaf', pizza: 'Cheese pizza', potpie: 'Chicken pot pie',
  burrito: 'Burrito', 'red wine': 'Wine', espresso: 'Black coffee', eggnog: 'Eggnog', corn: 'Corn on the cob',
};

// ---------- recognised-dish → nutrition ----------

const STOP = new Set(['with', 'and', 'the', 'of', 'de', 'la', 'le', 'al', 'alla', 'di', 'in', 'style', 'con', 'a', 'en', 'du', 'des', 'e', 'y']);

function stem(w) {
  if (w.length > 4 && w.endsWith('ies')) return `${w.slice(0, -3)}y`;
  if (w.length > 4 && w.endsWith('oes')) return w.slice(0, -2);
  if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) return w.slice(0, -1);
  return w;
}

const words = (s) => normalize(s).split(' ').filter((w) => w && !STOP.has(w)).map(stem);

// Phrase index: every food name (minus parentheticals) and alias, as stemmed word lists.
const PHRASES = FOODS.flatMap((f) => [f.name.replace(/\(.*?\)/g, ''), ...f.aliases].map((p) => ({ food: f, w: words(p) })).filter((p) => p.w.length));

// Rough per-serving estimates for dishes the database doesn't know, by keyword. Order matters:
// more specific dish types come first. A keyword matching the label's last word (its head noun,
// e.g. "Cucumber SOUP") wins over one matching elsewhere.
const DISH_KEYWORDS = [
  ['salad', ['salad', 'salat', 'slaw', 'tabbouleh', 'fattoush', 'larb', 'laab', 'som tam', 'kachumbari', 'gado', 'urap', 'namul', 'kosambari', 'pkhali', 'raita', 'tzatziki', 'cacik', 'tarator', 'pico de gallo', 'ceviche', 'poke', 'vinegret', 'curtido', 'lalab', 'asinan', 'rojak', 'yusheng'], { calories: 280, protein: 9, carbs: 18, fat: 19, serving: '1 bowl' }],
  ['soup', ['soup', 'broth', 'chowder', 'bisque', 'consomme', 'gazpacho', 'salmorejo', 'borscht', 'shchi', 'solyanka', 'rassolnik', 'okroshka', 'ukha', 'ciorba', 'chorba', 'chorbă', 'caldo', 'sopa', 'zuppa', 'minestra', 'ribollita', 'vichyssoise', 'avgolemono', 'magiritsa', 'harira', 'harees', 'tom yum', 'tom kha', 'guk', 'tang', 'jjigae', 'jeongol', 'suimono', 'dashi', 'miso', 'pozole', 'menudo', 'sinigang', 'soto', 'laksa', 'pho', 'bun bo', 'cawl', 'potage', 'velout', 'mulukhiyah', 'ash reshteh', 'kharcho', 'bouillabaisse', 'caldeirada', 'cullen skink', 'hochzeitssuppe', 'gulyasleves', 'czernina', 'zurek', 'kapusniak', 'garbure', 'potee', 'cocido', 'escudella', 'fabada', 'pistou', 'khash'], { calories: 240, protein: 13, carbs: 22, fat: 10, serving: '1 bowl' }],
  ['noodles', ['noodle', 'mein', 'mian', 'mien', 'ramen', 'udon', 'soba', 'somen', 'guksu', 'naengmyeon', 'japchae', 'pho', 'laksa', 'mee', 'mie', 'bihun', 'fen', 'fun', 'kway teow', 'pad', 'spaghetti', 'linguine', 'fettuccine', 'tagliatelle', 'pappardelle', 'penne', 'rigatoni', 'fusilli', 'macaroni', 'ravioli', 'tortellini', 'agnolotti', 'gnocchi', 'lasagn', 'pasta', 'spatzle', 'spaetzle', 'halusky', 'pizzoccheri', 'orecchiette', 'malloreddus', 'pici', 'trofie', 'garganelli', 'passatelli', 'pansotti', 'cumian', 'lamian', 'misua', 'idiyappam', 'fideua', 'tetrazzini'], { calories: 580, protein: 22, carbs: 78, fat: 19, serving: '1 plate' }],
  ['rice', ['rice', 'nasi', 'bap', 'bab', 'gohan', 'don', 'donburi', 'arroz', 'arros', 'risotto', 'paella', 'pilaf', 'pilau', 'plov', 'pulao', 'biryani', 'biriyani', 'khichdi', 'khichu', 'congee', 'jook', 'zosui', 'onigiri', 'chazuke', 'kedgeree', 'jambalaya', 'jollof', 'thieboudienne', 'maqluba', 'majboos', 'mandi', 'kabsa', 'tahdig', 'chelow', 'polo', 'pongal', 'puliyogare', 'chitranna', 'bisi', 'lontong', 'ketupat', 'xoi', 'com', 'sekihan', 'mochi'], { calories: 520, protein: 18, carbs: 75, fat: 15, serving: '1 plate' }],
  ['curry', ['curry', 'masala', 'korma', 'tikka', 'vindaloo', 'madras', 'rogan josh', 'jalfrezi', 'saag', 'palak', 'paneer', 'dal', 'daal', 'dhal', 'sambar', 'rasam', 'kadhi', 'rajma', 'chana', 'chole', 'aloo', 'gobi', 'nihari', 'haleem', 'qeema', 'keema', 'karahi', 'kaeng', 'gaeng', 'massaman', 'rendang', 'gulai', 'opor', 'kare', 'karē', 'adobo', 'kaldereta', 'menudo', 'mafe', 'maafe', 'moambe', 'ndole', 'wat', 'wot', 'tagine', 'tajine', 'stew', 'ragout', 'ragu', 'goulash', 'gulyas', 'paprikash', 'stroganoff', 'bourguignon', 'coq au vin', 'cassoulet', 'carbonade', 'daube', 'navarin', 'fricassee', 'fricasse', 'etouffee', 'gumbo', 'chili', 'chilli', 'feijoada', 'moqueca', 'yahni', 'stifado', 'giouvetsi', 'dolma', 'sarma', 'fesenjan', 'ghormeh', 'gheimeh', 'khoresh', 'hotpot', 'hot pot', 'nabe', 'sukiyaki', 'shabu', 'oden', 'nikujaga', 'kakuni', 'braised', 'kho', 'estofado', 'guisado', 'picadillo', 'ropa vieja', 'birria', 'barbacoa', 'mole', 'pepian', 'chakapuli', 'chanakhi', 'satsivi', 'lecso', 'pisto', 'ratatouille', 'caponata', 'piperade', 'shakshouka', 'menemen'], { calories: 470, protein: 26, carbs: 26, fat: 28, serving: '1 bowl' }],
  ['pizza', ['pizza', 'flammekueche', 'tarte flambee', 'manakish', 'lahmacun', 'pide', 'khachapuri', 'calzone', 'stromboli', 'focaccia', 'sfincione', 'coca', 'piadina'], { calories: 300, protein: 12, carbs: 35, fat: 12, serving: '1 slice' }],
  ['burger', ['burger', 'patty', 'jucy lucy', 'slider', 'patty melt', 'sloppy joe', 'loco moco'], { calories: 580, protein: 30, carbs: 40, fat: 32, serving: '1 burger' }],
  ['hot dog', ['hot dog', 'dog', 'frankfurter', 'wiener', 'polish', 'half smoke', 'bratwurst', 'currywurst', 'kielbasa', 'chorizo', 'sausage', 'wurst', 'boerewors', 'merguez', 'loukaniko', 'linguica', 'andouille', 'boudin', 'cudighi', 'salsiccia', 'korv', 'polse', 'pølse', 'makkara', 'kolbasz', 'klobasa', 'mititei', 'mici', 'cevapi', 'kebapche', 'sucuk', 'lap cheong', 'sai ua', 'longganisa'], { calories: 320, protein: 13, carbs: 18, fat: 22, serving: '1 serving' }],
  ['sandwich', ['sandwich', 'sub', 'hoagie', 'grinder', 'po boy', 'banh mi', 'torta', 'cemita', 'pambazo', 'muffuletta', 'panini', 'panino', 'tramezzino', 'croque', 'smorrebrod', 'smørrebrød', 'bocadillo', 'francesinha', 'mitraillette', 'chivito', 'bauru', 'cubano', 'reuben', 'pastrami', 'french dip', 'hot brown', 'runza', 'bierock', 'jibarito', 'roti john', 'kati roll', 'wrap', 'shawarma', 'doner', 'gyro', 'souvlaki', 'durum', 'arepa', 'pupusa', 'gordita', 'sope', 'huarache', 'tlayuda', 'tlacoyo', 'tostada', 'taco', 'taquito', 'flauta', 'burrito', 'chimichanga', 'enchilada', 'entomatada', 'quesadilla', 'chalupa', 'panucho', 'salbute', 'tamale', 'tamal', 'corunda', 'chilaquiles'], { calories: 480, protein: 23, carbs: 45, fat: 22, serving: '1 serving' }],
  ['dumplings', ['dumpling', 'jiaozi', 'baozi', 'bao', 'mandu', 'momo', 'gyoza', 'wonton', 'shumai', 'siu mai', 'har gow', 'xiaolongbao', 'khinkali', 'manti', 'pelmeni', 'vareniki', 'pierogi', 'pierog', 'kalduny', 'maultasche', 'knodel', 'knedle', 'kroppkaka', 'germknodel', 'dampfnudel', 'buuz', 'chuchvara', 'tortellini', 'ravioli', 'empanada', 'empanadilla', 'pastel', 'pastelito', 'samosa', 'samsa', 'somsa', 'gujia', 'karanji', 'modak', 'kachori', 'pirozhki', 'pirog', 'pasty', 'bridie', 'clanger', 'bolani', 'qutab', 'khuushuur', 'chebureki', 'borek', 'burek', 'banitsa', 'gibanica', 'tiropita', 'spanakopita', 'bougatsa', 'pastilla', 'briouat', 'brik', 'fatayer', 'sfiha', 'karelian', 'kalakukko', 'coulibiac', 'zongzi', 'lo mai', 'nikuman', 'mantou', 'anpan', 'siopao'], { calories: 380, protein: 15, carbs: 42, fat: 17, serving: '1 serving' }],
  ['pancake', ['pancake', 'crepe', 'blini', 'blintz', 'syrniki', 'pannenkoek', 'poffertjes', 'palatschinke', 'palacinke', 'nalesniki', 'racuchy', 'jeon', 'pajeon', 'buchimgae', 'okonomiyaki', 'dosa', 'uttapam', 'appam', 'injera', 'galette', 'crumpet', 'waffle', 'hotteok', 'jianbing', 'cong you bing', 'scallion', 'roti', 'paratha', 'chapati', 'puri', 'luchi', 'bhatura', 'kulcha', 'thalipeeth', 'bhakri', 'pathiri', 'lahoh', 'baghrir', 'msemen', 'yufka', 'lavash', 'markook', 'langos', 'fry bread', 'sopaipilla', 'vetkoek', 'puff puff', 'mandazi', 'oliebol', 'ploye', 'boxty', 'latke', 'rosti', 'draniki', 'raggmunk'], { calories: 330, protein: 9, carbs: 45, fat: 13, serving: '2 pieces' }],
  ['bread', ['bread', 'brood', 'brot', 'pan', 'pain', 'pane', 'bun', 'roll', 'loaf', 'naan', 'pita', 'bagel', 'baguette', 'ciabatta', 'challah', 'brioche', 'focaccia', 'bolillo', 'kaiser', 'pretzel', 'brezel', 'kalach', 'kalач', 'khubz', 'bing', 'shaobing', 'mantou', 'youtiao', 'bakarkhani', 'kulich', 'paska', 'babka', 'cozonac', 'tsoureki', 'panettone', 'pandoro', 'stollen', 'zopf', 'kringle', 'farl', 'scone', 'bannock', 'blaa', 'barmbrack', 'bara brith', 'rusk', 'zwieback', 'biscotti', 'grissini', 'taralli', 'cracker', 'manchet', 'potbrood', 'broa', 'pogaca', 'pogača', 'simit', 'kifli', 'kolach', 'kolache', 'buchteln', 'anpan', 'melonpan', 'pan dulce', 'concha', 'rosca'], { calories: 260, protein: 8, carbs: 46, fat: 5, serving: '1 piece' }],
  ['cake', ['cake', 'kuchen', 'torte', 'torta', 'taart', 'gateau', 'gâteau', 'tart', 'pie', 'cobbler', 'crumble', 'crisp', 'strudel', 'baklava', 'kanafeh', 'knafeh', 'kunafa', 'qatayef', 'basbousa', 'revani', 'galaktoboureko', 'mille feuille', 'napoleon', 'eclair', 'profiterole', 'croquembouche', 'choux', 'cream puff', 'cannoli', 'sfogliatella', 'pastiera', 'cassata', 'zeppole', 'struffoli', 'castagnaccio', 'tiramisu', 'trifle', 'pavlova', 'eton mess', 'roulade', 'swiss roll', 'yule log', 'buche', 'kouign', 'croissant', 'danish', 'pain au chocolat', 'madeleine', 'financier', 'clafoutis', 'far breton', 'kugelhopf', 'gugelhupf', 'savarin', 'baba', 'babka', 'makowiec', 'mazurek', 'sernik', 'kladdkaka', 'semla', 'princess', 'prinsesstarta', 'sachertorte', 'dobos', 'esterhazy', 'krempita', 'kremsnita', 'bienenstich', 'stollen', 'lamington', 'pound', 'sponge', 'castella', 'mooncake', 'taiyaki', 'imagawayaki', 'dorayaki', 'bebinca', 'bibingka', 'puto', 'kutsinta', 'kuih', 'kue', 'dodol', 'halwa', 'halva', 'halvah', 'sohan', 'cronut', 'brownie', 'blondie', 'bar', 'slice', 'square', 'scotcheroo'], { calories: 400, protein: 5, carbs: 52, fat: 19, serving: '1 slice' }],
  ['cookie', ['cookie', 'biscuit', 'macaron', 'macaroon', 'snickerdoodle', 'shortbread', 'speculaas', 'stroopwafel', 'ma amoul', 'maamoul', 'ghoriba', 'koulourakia', 'melomakarono', 'kourabiedes', 'polvoron', 'alfajor', 'amaretti', 'ricciarelli', 'cantucci', 'lebkuchen', 'pfeffernusse', 'krumkake', 'pizzelle', 'florentine', 'brandy snap', 'rugelach', 'hamantaschen', 'fortune', 'chikki', 'nankhatai', 'kokis'], { calories: 160, protein: 2, carbs: 21, fat: 8, serving: '2 pieces' }],
  ['pudding', ['pudding', 'custard', 'flan', 'creme brulee', 'creme caramel', 'panna cotta', 'cotta', 'mousse', 'souffle', 'parfait', 'kheer', 'payasam', 'phirni', 'firni', 'rabri', 'basundi', 'shrikhand', 'kulfi', 'falooda', 'muhallebi', 'malabi', 'sutlac', 'mahalabia', 'riz au lait', 'risalamande', 'rice pudding', 'arroz con leche', 'tapioca', 'sago', 'che', 'chè', 'tong sui', 'douhua', 'tofu pudding', 'annin', 'mango pudding', 'kissel', 'kisel', 'flummery', 'syllabub', 'fool', 'junket', 'blancmange', 'cranachan', 'jelly', 'gelatin', 'haupia', 'kakigori', 'shaved ice', 'shave ice', 'halo halo', 'ais kacang', 'cendol', 'bingsu', 'granita', 'sorbet', 'sherbet', 'gelato', 'ice cream', 'sundae', 'banana split', 'knickerbocker', 'affogato', 'semifreddo', 'dulce de leche', 'cajeta', 'brigadeiro', 'sweet', 'dessert', 'ambrosia'], { calories: 300, protein: 6, carbs: 42, fat: 12, serving: '1 cup' }],
  ['candy', ['candy', 'fudge', 'toffee', 'brittle', 'caramel', 'nougat', 'turron', 'turrón', 'marzipan', 'praline', 'truffle', 'bonbon', 'lokum', 'turkish delight', 'tanghulu', 'gozinaki', 'churchkhela', 'sachima', 'barfi', 'burfi', 'ladoo', 'laddu', 'peda', 'sandesh', 'rasgulla', 'rasagola', 'gulab jamun', 'jalebi', 'imarti', 'balushahi', 'ghevar', 'mysore pak', 'soan papdi', 'kaju katli', 'chomchom', 'malpua', 'chhena', 'rasmalai', 'ras malai', 'anarsa', 'sutarfeni', 'pootharekulu', 'kalakand', 'kalamay', 'suman', 'palitaw', 'sapin', 'mochi', 'dango', 'daifuku', 'manju', 'wagashi', 'namagashi', 'higashi', 'yokan', 'amanatto', 'tteok', 'yaksik', 'polkagris', 'krowki', 'szaloncukor', 'calisson', 'tulumba', 'lokma', 'loukoumades', 'sfenj', 'bambalouni', 'churro', 'beignet', 'donut', 'doughnut', 'paczki', 'krofne', 'berliner', 'malasada', 'fritule', 'crostoli', 'angel wings', 'chiacchiere', 'oreillette', 'kroštule'], { calories: 250, protein: 3, carbs: 38, fat: 10, serving: '1 serving' }],
  ['fried snack', ['fritter', 'pakora', 'bhaji', 'bhajji', 'vada', 'wada', 'bonda', 'punugulu', 'falafel', 'tempura', 'kakiage', 'katsu', 'tonkatsu', 'schnitzel', 'escalope', 'cordon bleu', 'cutlet', 'kotlet', 'croquette', 'korokke', 'croqueta', 'kroket', 'bitterballen', 'frikandel', 'arancini', 'supplì', 'suppli', 'panelle', 'crocchè', 'hush puppy', 'hushpuppy', 'akara', 'acaraje', 'kibbeh', 'koftas', 'karaage', 'chicharron', 'cuchifritos', 'tahu goreng', 'tahu', 'bakwan', 'perkedel', 'pisang goreng', 'banana chips', 'spring roll', 'egg roll', 'lumpia', 'cha gio', 'popiah', 'nem', 'samosa', 'mozzarella stick', 'onion ring', 'tots', 'poppers', 'chips', 'crisps', 'fries'], { calories: 380, protein: 10, carbs: 35, fat: 22, serving: '1 serving' }],
  ['porridge', ['porridge', 'congee', 'jook', 'oatmeal', 'grits', 'polenta', 'mamaliga', 'mămăligă', 'ugali', 'fufu', 'banku', 'kenkey', 'sadza', 'nshima', 'pap', 'tuwo', 'eba', 'garri', 'gari', 'amala', 'kokonte', 'asida', 'funge', 'funchi', 'cou cou', 'gachas', 'kasha', 'upma', 'khichdi', 'ogi', 'akamu', 'muesli', 'granola', 'cereal'], { calories: 280, protein: 7, carbs: 55, fat: 4, serving: '1 bowl' }],
  ['grilled meat', ['kebab', 'kabob', 'kabab', 'satay', 'sate', 'souvlaki', 'shashlik', 'shish', 'yakitori', 'yakiniku', 'bulgogi', 'galbi', 'kalbi', 'samgyeopsal', 'churrasco', 'asado', 'carne asada', 'al pastor', 'suya', 'sosatie', 'espetada', 'arrosticini', 'anticucho', 'pincho', 'jujeh', 'tikka', 'tandoori', 'barbecue', 'bbq', 'grill', 'roast', 'roasted', 'rotisserie', 'jingisukan', 'mechoui', 'lechon', 'suckling', 'siu yuk', 'char siu', 'babi panggang', 'porchetta', 'schweinshaxe', 'pork knuckle', 'ham', 'jamon', 'prosciutto', 'speck', 'bresaola', 'cecina', 'pastrami', 'smoked meat', 'corned beef', 'brisket', 'burnt ends', 'ribs', 'steak', 'chop', 'cutlet', 'tenderloin', 'loin', 'fillet', 'beef', 'pork', 'lamb', 'mutton', 'goat', 'veal', 'venison', 'reindeer', 'duck', 'goose', 'squab', 'pigeon', 'quail', 'rabbit', 'liver', 'tripe', 'tongue', 'oxtail', 'kidney', 'heart', 'trotter', 'meat'], { calories: 520, protein: 42, carbs: 6, fat: 36, serving: '1 plate' }],
  ['chicken', ['chicken', 'turkey', 'hen', 'poultry', 'ayam', 'gai', 'kai', 'pollo', 'poulet', 'frango', 'galinha', 'dak', 'murgh', 'tori'], { calories: 450, protein: 40, carbs: 14, fat: 25, serving: '1 plate' }],
  ['seafood', ['fish', 'salmon', 'tuna', 'cod', 'haddock', 'pollock', 'hake', 'halibut', 'trout', 'herring', 'sardine', 'anchovy', 'mackerel', 'eel', 'unagi', 'catfish', 'tilapia', 'snapper', 'sea bass', 'bream', 'carp', 'pike', 'perch', 'stingray', 'skate', 'swordfish', 'shrimp', 'prawn', 'scampi', 'lobster', 'crab', 'crayfish', 'langoustine', 'clam', 'mussel', 'oyster', 'scallop', 'squid', 'calamari', 'octopus', 'cuttlefish', 'sea urchin', 'roe', 'caviar', 'ikan', 'pla', 'pescado', 'bacalhau', 'bacalao', 'baccala', 'stockfish', 'lutefisk', 'rakfisk', 'gravlax', 'kipper', 'smokie', 'finnan', 'seafood', 'sushi', 'sashimi', 'poke', 'ceviche', 'aguachile', 'moules', 'paella', 'fideua'], { calories: 380, protein: 34, carbs: 14, fat: 19, serving: '1 plate' }],
  ['eggs', ['egg', 'omelette', 'omelet', 'frittata', 'tortilla espanola', 'quiche', 'shakshouka', 'menemen', 'huevos', 'oeufs', 'eggs benedict', 'chawanmushi', 'gyeran', 'tamago', 'tamagoyaki', 'kuku', 'cilbir', 'çılbır', 'pyttipanna', 'hangtown'], { calories: 320, protein: 18, carbs: 8, fat: 24, serving: '1 serving' }],
  ['tofu & beans', ['tofu', 'tempeh', 'natto', 'bean', 'beans', 'frijoles', 'feijao', 'fasole', 'pasulj', 'lobio', 'fasolada', 'gigantes', 'gigandes', 'revithia', 'chickpea', 'garbanzo', 'hummus', 'ful', 'foul', 'lentil', 'dal', 'daal', 'misal', 'usal', 'ghugni', 'chana', 'rajma', 'umngqusho', 'hoppin', 'succotash', 'edamame', 'baba ghanoush', 'mutabal', 'zaalouk', 'matbukha', 'makdous', 'muhammara', 'tahini', 'tarama', 'taramasalata', 'tirokafteri', 'urnebes', 'ajvar', 'dip'], { calories: 320, protein: 16, carbs: 38, fat: 12, serving: '1 bowl' }],
  ['cheese', ['cheese', 'fondue', 'raclette', 'queso', 'paneer', 'halloumi', 'feta', 'mozzarella', 'burrata', 'stracciatella', 'ricotta', 'brie', 'camembert', 'gouda', 'cheddar', 'gbejna', 'obatzda', 'smazeny syr', 'frico', 'aligot', 'truffade', 'welsh rarebit', 'rarebit', 'kaassouffle', 'kartoffelkase'], { calories: 400, protein: 20, carbs: 18, fat: 28, serving: '1 serving' }],
  ['potato', ['potato', 'potatoes', 'patatas', 'papas', 'pommes', 'tatties', 'gratin', 'dauphinois', 'hash', 'rosti', 'colcannon', 'stamppot', 'champ', 'bubble and squeak', 'papet', 'tartiflette', 'jansson', 'kopytka', 'cepelinai', 'kugelis', 'dum aloo', 'aloo'], { calories: 320, protein: 6, carbs: 45, fat: 14, serving: '1 serving' }],
  ['vegetables', ['vegetable', 'veggie', 'greens', 'cabbage', 'kimchi', 'sauerkraut', 'pickle', 'pickled', 'tsukemono', 'achar', 'spinach', 'kale', 'chard', 'eggplant', 'aubergine', 'zucchini', 'courgette', 'squash', 'pumpkin', 'mushroom', 'pepper', 'peppers', 'okra', 'bhindi', 'artichoke', 'carciofi', 'asparagus', 'broccoli', 'cauliflower', 'beet', 'beetroot', 'carrot', 'leek', 'onion', 'tomato', 'cucumber', 'corn', 'elote', 'nopal', 'nopalito', 'bamboo', 'lotus', 'seaweed', 'wakame', 'nori', 'gundruk', 'kinema', 'sabzi', 'sarson', 'stuffed', 'escalivada', 'imam bayildi', 'karniyarik', 'buddha', 'jeow'], { calories: 160, protein: 5, carbs: 18, fat: 8, serving: '1 cup' }],
  ['drink', ['drink', 'tea', 'chai', 'coffee', 'cafe', 'juice', 'lassi', 'smoothie', 'shake', 'milkshake', 'cocktail', 'punch', 'kompot', 'kvass', 'horchata', 'agua fresca', 'boba', 'bubble tea', 'chocolate caliente', 'hot chocolate', 'cocoa', 'eggnog', 'sharbat', 'falooda', 'ayran', 'doogh', 'solkadhi', 'buttermilk', 'kefir'], { calories: 180, protein: 4, carbs: 30, fat: 5, serving: '1 glass' }],
];

const GENERIC_DISH = { calories: 450, protein: 20, carbs: 45, fat: 20, serving: '1 plate' };

function keywordEstimate(label) {
  const norm = ` ${normalize(label)} `;
  const ws = words(label);
  const head = ws[ws.length - 1];
  const hit = (k) => norm.includes(` ${k} `) || norm.includes(` ${k}s `) || (k.length >= 5 && norm.includes(k));
  // Head noun first ("Cucumber soup" is a soup, not a cucumber).
  for (const [, keys, est] of DISH_KEYWORDS) if (keys.some((k) => !k.includes(' ') && stem(k) === head)) return est;
  for (const [, keys, est] of DISH_KEYWORDS) if (keys.some(hit)) return est;
  return null;
}

// Words that change what a dish is, so "Crab cake" isn't treated as a dessert or "Sea cucumber" as a vegetable.
const MODIFIERS = new Set(['crab', 'clam', 'lobster', 'fish', 'shrimp', 'prawn', 'oyster', 'salmon', 'tuna', 'sea', 'pork', 'beef', 'lamb', 'mutton', 'rabbit', 'chicken', 'meat', 'cabbage', 'arctic', 'angel', 'jelly', 'swiss', 'apple', 'moule', 'hangtown', 'potato', 'rice', 'cheese', 'egg', 'tofu', 'bean', 'pot', 'scotch', 'pasta', 'macaroni', 'jello', 'snicker', 'watergate', 'frogeye', 'cookie', 'glorified']);

// Maps a recognised dish label to a database entry or a dish-type estimate.
const BY_NAME = new Map(FOODS.map((f) => [f.name, f]));

export function foodForLabel(label) {
  if (BY_NAME.has(label)) return { food: BY_NAME.get(label), exact: true };
  const lw = words(label);
  if (!lw.length) return null;
  const head = lw[lw.length - 1];
  const modified = lw.slice(0, -1).some((w) => MODIFIERS.has(w));
  let best = null;
  let bestScore = 0;
  for (const p of PHRASES) {
    if (!p.w.every((w) => lw.includes(w))) continue;
    const coverage = new Set(p.w).size / new Set(lw).size; // unique words, so "Double-Double" ≠ "Double Down"

    // Accept full matches, or partial ones that share the dish's head noun ("Chicken CURRY" → curry).
    if (coverage < 1 && !(p.w[p.w.length - 1] === head && coverage >= 0.34 && !(modified && !p.w.some((w) => MODIFIERS.has(w))))) continue;
    const score = coverage * 10 + p.w.length;
    if (score > bestScore) {
      bestScore = score;
      best = p;
    }
  }
  const bare = (x) => normalize(x.replace(/\(.*?\)/g, ''));
  if (best) return { food: best.food, exact: best.food.name === label || bare(best.food.name) === bare(label) };
  const est = keywordEstimate(label) || GENERIC_DISH;
  return { food: { id: `est:${normalize(label)}`, name: label, category: 'Estimated', aliases: [], ...est }, estimated: true, generic: est === GENERIC_DISH };
}
