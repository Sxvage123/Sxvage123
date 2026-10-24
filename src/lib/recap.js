// Weekly recap numbers (pure, tested).

import { weekDays } from './dates.js';
import { dayTotals, dailyQuests, challengeProgress } from './game.js';

export function weeklyRecap(state, stats, weekStartKey) {
  const days = weekDays(weekStartKey);
  const logged = days.map((d) => dayTotals(state, d)).filter((t) => t.meals > 0);
  const avg = (k) => (logged.length ? Math.round(logged.reduce((s, t) => s + t[k], 0) / logged.length) : 0);
  let proteinDays = 0;
  let targetDays = 0;
  let challenges = 0;
  for (const d of days) {
    const q = dailyQuests(state, d);
    if (q[1].done) proteinDays++;
    if (q[2].done) targetDays++;
    if (challengeProgress(state, d)?.done) challenges++;
  }
  const xp = days.reduce((s, d) => s + (stats.xpByDay.get(d)?.total || 0), 0);
  const inWeek = state.scans.filter((s) => days.includes(s.date)).sort((a, b) => a.time.localeCompare(b.time));
  const before = state.scans.filter((s) => s.date < days[0]).sort((a, b) => a.time.localeCompare(b.time));
  const lastBf = inWeek.length ? inWeek[inWeek.length - 1].bodyFat : null;
  const prevBf = before.length ? before[before.length - 1].bodyFat : null;
  return {
    xp,
    daysLogged: logged.length,
    meals: logged.reduce((s, t) => s + t.meals, 0),
    avgCalories: avg('calories'),
    avgProtein: avg('protein'),
    proteinDays,
    targetDays,
    challenges,
    bodyFat: lastBf,
    bodyFatChange: lastBf !== null && prevBf !== null ? Math.round((lastBf - prevBf) * 10) / 10 : null,
  };
}
