import { test } from 'node:test';
import assert from 'node:assert/strict';
import { weeklyRecap } from '../src/lib/recap.js';

test('weekly recap summarises a week', () => {
  const s = { profile: { goal: 'cut', calorieGoal: 2000, proteinGoal: 150 }, meals: [], scans: [], challenges: {} };
  for (const d of ['2026-03-02', '2026-03-03', '2026-03-04']) {
    for (let i = 0; i < 3; i++) s.meals.push({ id: d + i, date: d, time: `${d}T1${i}:00`, calories: 600, protein: 55, carbs: 0, fat: 0 });
  }
  s.challenges['2026-03-03'] = { metric: 'manual', target: 1, title: 'x', xp: 80, done: true };
  s.scans.push({ id: 'a', date: '2026-02-23', time: '2026-02-23T08', bodyFat: 20 });
  s.scans.push({ id: 'b', date: '2026-03-05', time: '2026-03-05T08', bodyFat: 19.2 });
  const r = weeklyRecap(s, '2026-03-02');
  assert.equal(r.daysLogged, 3);
  assert.equal(r.meals, 9);
  assert.equal(r.avgCalories, 1800);
  assert.equal(r.proteinDays, 3);
  assert.equal(r.targetDays, 3);
  assert.equal(r.challenges, 1);
  assert.equal(r.bodyFatChange, -0.8);
});
