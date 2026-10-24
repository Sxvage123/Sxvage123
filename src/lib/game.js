// The grind engine. Every number here is derived from the logged data (meals, scans,
// challenges), so XP can never drift out of sync or be double-awarded.

import { addDays, daysBetween, dayKey, weekStart, weekDays } from './dates.js';
import { TARGET_WINDOW } from './nutrition.js';

export const RANKS = [
  { name: 'Iron', min: 0, color: '#9aa3ad', glow: '#5b636c' },
  { name: 'Bronze', min: 400, color: '#e0915a', glow: '#8a4b22' },
  { name: 'Silver', min: 1200, color: '#d5dde6', glow: '#7d8792' },
  { name: 'Gold', min: 2500, color: '#ffd34d', glow: '#b8860b' },
  { name: 'Platinum', min: 4500, color: '#5ee6d0', glow: '#178a7a' },
  { name: 'Diamond', min: 7500, color: '#6fb6ff', glow: '#1f5fbf' },
  { name: 'Master', min: 11500, color: '#c084fc', glow: '#7e22ce' },
  { name: 'Grandmaster', min: 17000, color: '#ff5d7a', glow: '#be123c' },
  { name: 'Legend', min: 25000, color: '#d4ff3a', glow: '#65a30d' },
];

const DIVISIONS = ['III', 'II', 'I'];

export const XP = {
  meal: 10,
  mealCap: 6,
  fullLog: 20, // 3+ meals logged
  protein: 40,
  calories: 40,
  scan: 50,
  newLowPerPoint: 100, // per body-fat percentage point below your previous best
  newLowCap: 300,
  maxStreakBonus: 0.5, // +5% per streak day, capped at +50%
};

export function rankFor(xp) {
  let index = 0;
  for (let i = 0; i < RANKS.length; i++) if (xp >= RANKS[i].min) index = i;
  const rank = RANKS[index];
  const next = RANKS[index + 1];
  if (!next) {
    return { ...rank, index, division: '', title: rank.name, progress: 1, floor: rank.min, nextAt: null, nextTitle: null };
  }
  const span = (next.min - rank.min) / 3;
  const div = Math.min(2, Math.floor((xp - rank.min) / span));
  const floor = rank.min + div * span;
  const nextAt = Math.round(floor + span);
  const nextTitle = div < 2 ? `${rank.name} ${DIVISIONS[div + 1]}` : `${next.name}${RANKS[index + 2] ? ' III' : ''}`;
  return {
    ...rank,
    index,
    division: DIVISIONS[div],
    title: `${rank.name} ${DIVISIONS[div]}`,
    tier: index * 3 + div, // monotonic number for "did I rank up?"
    progress: (xp - floor) / span,
    floor: Math.round(floor),
    nextAt,
    nextTitle,
  };
}

export function levelFor(xp) {
  // Gentle curve: each level needs a little more XP than the last.
  let level = 1;
  let need = 100;
  let acc = 0;
  while (xp >= acc + need) {
    acc += need;
    level += 1;
    need = Math.round(100 + level * 15);
  }
  return { level, into: xp - acc, need, progress: (xp - acc) / need };
}

// ---------- per-day nutrition ----------

export function mealsOn(state, date) {
  return state.meals.filter((m) => m.date === date);
}

export function dayTotals(state, date) {
  const t = { calories: 0, protein: 0, carbs: 0, fat: 0, meals: 0 };
  for (const m of mealsOn(state, date)) {
    t.calories += m.calories || 0;
    t.protein += m.protein || 0;
    t.carbs += m.carbs || 0;
    t.fat += m.fat || 0;
    t.meals += 1;
  }
  return t;
}

export function caloriesOnTarget(state, totals) {
  const p = state.profile;
  if (!p || totals.meals < 2) return false;
  const [lo, hi] = TARGET_WINDOW[p.goal] || TARGET_WINDOW.maintain;
  return totals.calories >= p.calorieGoal * lo && totals.calories <= p.calorieGoal * hi;
}

// The three automatic daily quests. Each is verified from the food log.
export function dailyQuests(state, date) {
  const t = dayTotals(state, date);
  const p = state.profile || {};
  const [lo, hi] = TARGET_WINDOW[p.goal] || TARGET_WINDOW.maintain;
  return [
    {
      id: 'log3',
      title: 'Log 3 meals',
      current: Math.min(t.meals, 3),
      target: 3,
      xp: XP.fullLog,
      done: t.meals >= 3,
    },
    {
      id: 'protein',
      title: `Hit ${p.proteinGoal || 0}g protein`,
      current: Math.round(t.protein),
      target: p.proteinGoal || 0,
      xp: XP.protein,
      done: !!p.proteinGoal && t.protein >= p.proteinGoal,
    },
    {
      id: 'calories',
      title: `Land ${Math.round((p.calorieGoal || 0) * lo)}–${Math.round((p.calorieGoal || 0) * hi)} kcal`,
      current: Math.round(t.calories),
      target: p.calorieGoal || 0,
      xp: XP.calories,
      done: caloriesOnTarget(state, t),
      hint: t.meals < 2 ? 'Needs at least 2 meals logged' : '',
    },
  ];
}

// ---------- challenges ----------

export function challengeProgress(state, date) {
  const c = state.challenges[date];
  if (!c) return null;
  const t = dayTotals(state, date);
  let current = 0;
  let auto = true;
  switch (c.metric) {
    case 'meals_logged':
      current = t.meals;
      break;
    case 'protein_g':
      current = Math.round(t.protein);
      break;
    case 'calories_on_target':
      current = caloriesOnTarget(state, t) ? 1 : 0;
      break;
    case 'body_scan':
      current = state.scans.filter((s) => s.date === date).length;
      break;
    default:
      auto = false;
      current = c.done ? c.target : 0;
  }
  const done = auto ? current >= c.target : !!c.done;
  return { ...c, current: Math.min(current, c.target), auto, done };
}

// ---------- activity, streaks & freezes ----------

export function activeDays(state) {
  const days = new Set();
  for (const m of state.meals) days.add(m.date);
  for (const s of state.scans) days.add(s.date);
  for (const [d, c] of Object.entries(state.challenges)) if (c.done) days.add(d);
  return days;
}

// Walks every day from your first activity to today. Each 7 active days in a row
// earns a streak freeze (max 2 banked); a missed day burns one instead of the streak.
export function streakInfo(state, today = dayKey()) {
  const active = activeDays(state);
  const result = { current: 0, best: 0, freezes: 0, frozen: new Set(), byDay: new Map(), activeToday: active.has(today), atRisk: false };
  if (!active.size) return result;
  const first = [...active].sort()[0];
  let streak = 0;
  let sinceFreeze = 0;
  let freezes = 0;
  for (let d = first; daysBetween(d, today) >= 0; d = addDays(d, 1)) {
    if (active.has(d)) {
      streak += 1;
      sinceFreeze += 1;
      if (sinceFreeze >= 7) {
        sinceFreeze = 0;
        freezes = Math.min(2, freezes + 1);
      }
    } else if (d === today) {
      // Today isn't over yet: the streak is pending, not broken.
    } else if (streak > 0 && freezes > 0) {
      freezes -= 1;
      result.frozen.add(d);
    } else {
      streak = 0;
      sinceFreeze = 0;
    }
    result.byDay.set(d, streak);
    result.best = Math.max(result.best, streak);
  }
  result.current = streak;
  result.freezes = freezes;
  result.atRisk = streak > 0 && !result.activeToday;
  return result;
}

export function streakMultiplier(streakDays) {
  return 1 + Math.min(XP.maxStreakBonus, Math.max(0, streakDays - 1) * 0.05);
}

// ---------- XP ----------

export function dayXP(state, date, streak) {
  const items = [];
  const meals = mealsOn(state, date).length;
  if (meals) items.push({ label: `${Math.min(meals, XP.mealCap)} meal${meals > 1 ? 's' : ''} logged`, xp: Math.min(meals, XP.mealCap) * XP.meal });
  for (const q of dailyQuests(state, date)) if (q.done) items.push({ label: q.title, xp: q.xp });
  const ch = challengeProgress(state, date);
  if (ch && ch.done) items.push({ label: `Challenge: ${ch.title}`, xp: ch.xp });
  const base = items.reduce((s, i) => s + i.xp, 0);
  const streakDays = streak ? streak.byDay.get(date) || 0 : 0;
  const mult = base ? streakMultiplier(streakDays) : 1;
  const bonus = Math.round(base * (mult - 1));
  if (bonus) items.push({ label: `🔥 ${streakDays}-day streak ×${mult.toFixed(2)}`, xp: bonus });
  return { items, total: base + bonus, multiplier: mult };
}

// Scan XP: one scan per day pays out; beating your best (lowest) body fat pays more.
export function scanXP(state) {
  const byDate = new Map();
  const sorted = [...state.scans].sort((a, b) => a.time.localeCompare(b.time));
  let best = null;
  const seen = new Set();
  for (const s of sorted) {
    const items = [];
    if (!seen.has(s.date)) {
      seen.add(s.date);
      items.push({ label: 'Body scan', xp: XP.scan });
    }
    if (best !== null && s.bodyFat <= best - 0.5) {
      const xp = Math.min(XP.newLowCap, Math.round((best - s.bodyFat) * XP.newLowPerPoint));
      items.push({ label: `New body-fat low (−${(best - s.bodyFat).toFixed(1)}%)`, xp });
    }
    if (best === null || s.bodyFat < best) best = s.bodyFat;
    const list = byDate.get(s.date) || [];
    list.push(...items.map((i) => ({ ...i, scanId: s.id })));
    byDate.set(s.date, list);
  }
  return byDate;
}

export function computeStats(state, today = dayKey()) {
  const streak = streakInfo(state, today);
  const scanByDate = scanXP(state);
  const dates = new Set([...activeDays(state), ...scanByDate.keys(), ...Object.keys(state.challenges)]);
  const xpByDay = new Map();
  let total = 0;
  for (const d of dates) {
    const dx = dayXP(state, d, streak);
    const sx = scanByDate.get(d) || [];
    const items = [...dx.items, ...sx];
    const sum = items.reduce((s, i) => s + i.xp, 0);
    if (sum) xpByDay.set(d, { items, total: sum, multiplier: dx.multiplier });
    total += sum;
  }
  const rank = rankFor(total);
  const level = levelFor(total);
  const challengesDone = Object.keys(state.challenges).filter((d) => challengeProgress(state, d)?.done).length;
  return { xp: total, rank, level, streak, xpByDay, challengesDone };
}

export function weekXP(stats, startKey) {
  return weekDays(startKey).reduce((s, d) => s + (stats.xpByDay.get(d)?.total || 0), 0);
}

// ---------- badges ----------

export const BADGES = [
  { id: 'first_bite', icon: '🍽️', name: 'First Bite', desc: 'Log your first meal', test: (s) => s.meals >= 1 },
  { id: 'meal_50', icon: '📒', name: 'Logbook', desc: 'Log 50 meals', test: (s) => s.meals >= 50 },
  { id: 'meal_250', icon: '📚', name: 'Archivist', desc: 'Log 250 meals', test: (s) => s.meals >= 250 },
  { id: 'scan_1', icon: '📸', name: 'Mirror Check', desc: 'Complete a body scan', test: (s) => s.scans >= 1 },
  { id: 'scan_10', icon: '🧬', name: 'Data Driven', desc: 'Complete 10 body scans', test: (s) => s.scans >= 10 },
  { id: 'streak_3', icon: '🔥', name: 'Heating Up', desc: '3-day streak', test: (s) => s.bestStreak >= 3 },
  { id: 'streak_7', icon: '⚡', name: 'Week Warrior', desc: '7-day streak', test: (s) => s.bestStreak >= 7 },
  { id: 'streak_30', icon: '🌋', name: 'Unstoppable', desc: '30-day streak', test: (s) => s.bestStreak >= 30 },
  { id: 'streak_100', icon: '👑', name: 'Centurion', desc: '100-day streak', test: (s) => s.bestStreak >= 100 },
  { id: 'chal_1', icon: '🎯', name: 'Challenger', desc: 'Complete a daily challenge', test: (s) => s.challenges >= 1 },
  { id: 'chal_10', icon: '🏹', name: 'Sharpshooter', desc: 'Complete 10 challenges', test: (s) => s.challenges >= 10 },
  { id: 'chal_50', icon: '🗡️', name: 'Gladiator', desc: 'Complete 50 challenges', test: (s) => s.challenges >= 50 },
  { id: 'protein_7', icon: '🥩', name: 'Protein Machine', desc: 'Hit protein 7 days', test: (s) => s.proteinDays >= 7 },
  { id: 'target_7', icon: '🎚️', name: 'Dialed In', desc: 'On-target calories 7 days', test: (s) => s.targetDays >= 7 },
  { id: 'drop_1', icon: '📉', name: 'Leaning Out', desc: 'Drop 1% body fat from your first scan', test: (s) => s.bfDrop >= 1 },
  { id: 'drop_3', icon: '🗿', name: 'Chiseled', desc: 'Drop 3% body fat from your first scan', test: (s) => s.bfDrop >= 3 },
  { id: 'drop_5', icon: '💎', name: 'Shredded', desc: 'Drop 5% body fat from your first scan', test: (s) => s.bfDrop >= 5 },
  { id: 'gold', icon: '🥇', name: 'Gold Standard', desc: 'Reach Gold rank', test: (s) => s.rankIndex >= 3 },
  { id: 'diamond', icon: '💠', name: 'Diamond Hands', desc: 'Reach Diamond rank', test: (s) => s.rankIndex >= 5 },
  { id: 'legend', icon: '🌟', name: 'Legendary', desc: 'Reach Legend rank', test: (s) => s.rankIndex >= 8 },
  { id: 'league_win', icon: '🏆', name: 'Promoted', desc: 'Get promoted in the weekly league', test: (s) => s.promotions >= 1 },
];

export function badgeStats(state, stats) {
  const days = new Set(state.meals.map((m) => m.date));
  let proteinDays = 0;
  let targetDays = 0;
  for (const d of days) {
    const q = dailyQuests(state, d);
    if (q[1].done) proteinDays++;
    if (q[2].done) targetDays++;
  }
  const scans = [...state.scans].sort((a, b) => a.time.localeCompare(b.time));
  const bfDrop = scans.length > 1 ? scans[0].bodyFat - Math.min(...scans.map((s) => s.bodyFat)) : 0;
  return {
    meals: state.meals.length,
    scans: scans.length,
    bestStreak: stats.streak.best,
    challenges: stats.challengesDone,
    proteinDays,
    targetDays,
    bfDrop,
    rankIndex: stats.rank.index,
    promotions: (state.league?.history || []).filter((h) => h.result === 'promoted').length,
  };
}

export function earnedBadges(state, stats) {
  const s = badgeStats(state, stats);
  return BADGES.map((b) => ({ ...b, earned: b.test(s) }));
}
