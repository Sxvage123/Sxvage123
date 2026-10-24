// Daily challenge generator. Fully offline: picks from a template pool, seeded by the date,
// and scales reps/targets with your rank so the grind keeps getting harder.

import { daysBetween, parseDay } from './dates.js';
import { seeded, pick } from './rng.js';

const XP_BY_DIFFICULTY = { easy: 50, medium: 80, hard: 120 };

// scale(n) multiplies by the rank difficulty factor and rounds to a friendly number.
const TRAINING = [
  { title: (n) => `${n} push-ups`, base: 40, step: 5, unit: 'reps', icon: '💪', desc: 'Split into as many sets as you need. Chest to fist, full lockout.' },
  { title: (n) => `${n} bodyweight squats`, base: 60, step: 10, unit: 'reps', icon: '🦵', desc: 'Hips below knees, chest up. Break it into sets.' },
  { title: (n) => `${n} walking lunges`, base: 40, step: 10, unit: 'reps', icon: '🚶', desc: 'Count each leg. Long strides, back knee kisses the floor.' },
  { title: (n) => `${n}s total plank`, base: 120, step: 30, unit: 'seconds', icon: '🧱', desc: 'Accumulate the time across sets. Squeeze glutes, no sagging.' },
  { title: (n) => `${n} burpees`, base: 30, step: 5, unit: 'reps', icon: '⚡', desc: 'Chest to floor, jump at the top. Pace yourself.' },
  { title: (n) => `${n} jumping jacks`, base: 150, step: 25, unit: 'reps', icon: '⭐', desc: 'Great as a warm-up or between work blocks.' },
  { title: (n) => `${n}s wall sit`, base: 120, step: 30, unit: 'seconds', icon: '🪑', desc: 'Thighs parallel to the floor. Accumulate across sets.' },
  { title: (n) => `${n} sit-ups`, base: 50, step: 10, unit: 'reps', icon: '🔩', desc: 'Controlled tempo, no yanking on your neck.' },
  { title: (n) => `${n} glute bridges`, base: 60, step: 10, unit: 'reps', icon: '🍑', desc: 'Pause and squeeze for a second at the top.' },
  { title: (n) => `${n} mountain climbers`, base: 100, step: 20, unit: 'reps', icon: '⛰️', desc: 'Count each knee drive. Keep hips low.' },
  { title: (n) => `Walk ${n.toLocaleString()} steps`, base: 8000, step: 1000, unit: 'steps', icon: '👟', desc: 'Check your phone’s step counter before you mark it done.' },
  { title: (n) => `${n}-minute run or brisk walk`, base: 20, step: 5, unit: 'minutes', icon: '🏃', desc: 'Conversational pace is fine. Just keep moving.' },
  { title: (n) => `${n} pull-ups or rows`, base: 20, step: 5, unit: 'reps', icon: '🧗', desc: 'Pull-ups, chin-ups or table rows all count.' },
  { title: (n) => `${n} minutes of stretching`, base: 10, step: 2, unit: 'minutes', icon: '🧘', desc: 'Hips, hamstrings, chest and shoulders. Breathe slowly.' },
];

const LIFESTYLE = [
  { title: () => 'Drink 3 litres of water', icon: '💧', desc: 'About 12 glasses. Front-load it so you are not up all night.' },
  { title: () => 'Zero sugary drinks today', icon: '🚫', desc: 'No soda, sweet tea, energy drinks or juice. Water, black coffee and tea are fine.' },
  { title: () => 'No snacks after 9 pm', icon: '🌙', desc: 'Kitchen closes at 9. Brush your teeth early if it helps.' },
  { title: () => 'Eat 3 servings of vegetables', icon: '🥦', desc: 'A serving is a fist-sized portion. Bonus points for green.' },
  { title: () => 'Sleep 8 hours tonight', icon: '😴', desc: 'Mark it done tomorrow morning if you hit it — muscles grow while you sleep.' },
  { title: () => 'Cook every meal yourself', icon: '🍳', desc: 'No takeout or fast food today. You control the portions.' },
  { title: () => '10-minute walk after a meal', icon: '🌤️', desc: 'Post-meal walks help blunt blood sugar spikes.' },
];

const NUTRITION = [
  { metric: 'meals_logged', target: () => 4, title: () => 'Log 4 meals or snacks', icon: '📝', desc: 'Every bite counts — snacks included. Auto-tracked from your food log.' },
  { metric: 'protein_g', target: (ctx) => Math.round((ctx.proteinGoal || 120) * 1.1), title: (n) => `Smash ${n}g of protein`, icon: '🥩', desc: '10% over your normal target. Auto-tracked from your food log.' },
  { metric: 'calories_on_target', target: () => 1, title: () => 'Land your calories on target', icon: '🎯', desc: 'Log at least 2 meals and finish inside your calorie window. Auto-tracked.' },
];

export function difficultyFactor(rankIndex) {
  return 1 + Math.min(rankIndex, 8) * 0.18;
}

function roundTo(n, step) {
  return Math.max(step, Math.round(n / step) * step);
}

// ctx: { date, rankIndex, proteinGoal, lastScanDate, reroll }
export function generateChallenge(ctx) {
  const rand = seeded(`challenge:${ctx.date}:${ctx.reroll || 0}`);
  const dow = parseDay(ctx.date).getDay();
  const boss = dow === 0; // Sunday boss fight: harder, double XP
  const scanDue = !ctx.lastScanDate || daysBetween(ctx.lastScanDate, ctx.date) >= 7;

  // Weighted pick of challenge family.
  let family;
  const r = rand();
  if (scanDue && !ctx.reroll && dow === 1) family = 'scan'; // Monday check-in when a scan is due
  else if (boss) family = 'training';
  else if (r < 0.55) family = 'training';
  else if (r < 0.8) family = 'nutrition';
  else family = 'lifestyle';

  const factor = difficultyFactor(ctx.rankIndex || 0) * (boss ? 1.6 : 1);
  const difficulty = boss ? 'hard' : factor >= 1.9 ? 'hard' : factor >= 1.35 ? 'medium' : 'easy';
  let c;
  if (family === 'scan') {
    c = { metric: 'body_scan', target: 1, title: 'Weekly body scan check-in', icon: '📸', description: 'Same spot, same lighting, same time of day. Consistency makes your trend line accurate.' };
  } else if (family === 'training') {
    const t = pick(rand, TRAINING);
    const n = roundTo(t.base * factor, t.step);
    c = { metric: 'manual', target: 1, title: t.title(n), icon: t.icon, description: t.desc, amount: n, unit: t.unit };
  } else if (family === 'nutrition') {
    const t = pick(rand, NUTRITION);
    const target = t.target(ctx);
    c = { metric: t.metric, target, title: t.title(target), icon: t.icon, description: t.desc };
  } else {
    const t = pick(rand, LIFESTYLE);
    c = { metric: 'manual', target: 1, title: t.title(), icon: t.icon, description: t.desc };
  }
  const xp = Math.round(XP_BY_DIFFICULTY[difficulty] * (boss ? 2 : 1));
  return { ...c, difficulty, xp, boss, family, reroll: ctx.reroll || 0, done: false, createdAt: new Date().toISOString() };
}
