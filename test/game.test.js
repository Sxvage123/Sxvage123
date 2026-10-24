import { test } from 'node:test';
import assert from 'node:assert/strict';
import { rankFor, levelFor, streakInfo, computeStats, dailyQuests, scanXP, streakMultiplier, earnedBadges, challengeProgress } from '../src/lib/game.js';
import { addDays } from '../src/lib/dates.js';
import { generateChallenge } from '../src/lib/challenges.js';
import { settleLeague, standings } from '../src/lib/league.js';

const profile = { sex: 'male', goal: 'cut', calorieGoal: 2000, proteinGoal: 150 };
const blank = () => ({ profile, meals: [], scans: [], challenges: {}, league: null });
const meal = (date, calories, protein = 0, id = Math.random().toString(36)) => ({ id, date, time: `${date}T12:00:00`, calories, protein, carbs: 0, fat: 0 });

test('ranks and divisions', () => {
  assert.equal(rankFor(0).title, 'Iron III');
  assert.equal(rankFor(399).title, 'Iron I');
  assert.equal(rankFor(400).title, 'Bronze III');
  assert.equal(rankFor(25000).title, 'Legend');
  assert.equal(rankFor(24999).nextTitle, 'Legend');
  assert.ok(rankFor(500).tier > rankFor(399).tier);
});

test('levels grow monotonically', () => {
  let prev = 0;
  for (let xp = 0; xp < 30000; xp += 137) {
    const l = levelFor(xp).level;
    assert.ok(l >= prev);
    prev = l;
  }
  assert.equal(levelFor(0).level, 1);
  assert.equal(levelFor(100).level, 2);
});

test('streak counts consecutive days and today is pending', () => {
  const s = blank();
  const today = '2026-03-10';
  for (let i = 1; i <= 4; i++) s.meals.push(meal(addDays(today, -i), 500));
  const info = streakInfo(s, today);
  assert.equal(info.current, 4);
  assert.equal(info.atRisk, true);
  s.meals.push(meal(today, 500));
  assert.equal(streakInfo(s, today).current, 5);
});

test('missed day breaks streak without freeze, freeze saves it after 7 days', () => {
  const s = blank();
  const today = '2026-03-20';
  // days -3..-1 active, -4 missed, -5 active -> streak 3
  for (const i of [5, 3, 2, 1]) s.meals.push(meal(addDays(today, -i), 500));
  assert.equal(streakInfo(s, today).current, 3);

  const t = blank();
  for (let i = 15; i >= 8; i--) t.meals.push(meal(addDays(today, -i), 500)); // 8 days active
  for (let i = 6; i >= 1; i--) t.meals.push(meal(addDays(today, -i), 500)); // miss day -7
  const info = streakInfo(t, today);
  assert.equal(info.frozen.has(addDays(today, -7)), true);
  assert.equal(info.current, 14);
});

test('daily quests and XP', () => {
  const s = blank();
  const d = '2026-03-10';
  s.meals.push(meal(d, 600, 50), meal(d, 700, 50), meal(d, 600, 60));
  const q = dailyQuests(s, d);
  assert.deepEqual(q.map((x) => x.done), [true, true, true]);
  const stats = computeStats(s, d);
  // 3 meals*10 + 20 + 40 + 40 = 130, first day of streak -> x1
  assert.equal(stats.xp, 130);
});

test('calories out of window do not count', () => {
  const s = blank();
  const d = '2026-03-10';
  s.meals.push(meal(d, 2500), meal(d, 300));
  assert.equal(dailyQuests(s, d)[2].done, false);
});

test('streak multiplier caps at 1.5', () => {
  assert.equal(streakMultiplier(1), 1);
  assert.equal(streakMultiplier(3), 1.1);
  assert.equal(streakMultiplier(100), 1.5);
});

test('scan XP: one per day, bonus for new low', () => {
  const s = blank();
  s.scans = [
    { id: 'a', date: '2026-03-01', time: '2026-03-01T08:00', bodyFat: 20 },
    { id: 'b', date: '2026-03-01', time: '2026-03-01T09:00', bodyFat: 20.2 },
    { id: 'c', date: '2026-03-08', time: '2026-03-08T08:00', bodyFat: 18.5 },
    { id: 'd', date: '2026-03-09', time: '2026-03-09T08:00', bodyFat: 18.3 },
  ];
  const x = scanXP(s);
  assert.equal(x.get('2026-03-01').reduce((a, i) => a + i.xp, 0), 50);
  assert.equal(x.get('2026-03-08').reduce((a, i) => a + i.xp, 0), 200);
  assert.equal(x.get('2026-03-09').reduce((a, i) => a + i.xp, 0), 50); // only 0.2 lower: no bonus
});

test('challenge generator is deterministic and auto-verifies nutrition', () => {
  const a = generateChallenge({ date: '2026-03-11', rankIndex: 2, proteinGoal: 150 });
  const b = generateChallenge({ date: '2026-03-11', rankIndex: 2, proteinGoal: 150 });
  assert.equal(a.title, b.title);
  const r = generateChallenge({ date: '2026-03-11', rankIndex: 2, proteinGoal: 150, reroll: 1 });
  assert.ok(r.xp > 0);
  const sunday = generateChallenge({ date: '2026-03-15', rankIndex: 0 });
  assert.equal(sunday.boss, true);
  const s = blank();
  s.challenges['2026-03-11'] = { metric: 'meals_logged', target: 2, title: 't', xp: 80 };
  s.meals.push(meal('2026-03-11', 100), meal('2026-03-11', 100));
  assert.equal(challengeProgress(s, '2026-03-11').done, true);
  s.challenges['2026-03-12'] = { metric: 'manual', target: 1, title: 'pushups', xp: 80, done: false };
  assert.equal(challengeProgress(s, '2026-03-12').done, false);
});

test('every challenge across a year is valid', () => {
  let d = '2026-01-01';
  for (let i = 0; i < 365; i++) {
    for (let rank = 0; rank < 9; rank += 4) {
      const c = generateChallenge({ date: d, rankIndex: rank, proteinGoal: 140, lastScanDate: null });
      assert.ok(c.title && !c.title.includes('NaN') && !c.title.includes('undefined'), c.title);
      assert.ok(c.xp >= 50 && c.target >= 1);
    }
    d = addDays(d, 1);
  }
});

test('league settles past weeks with promotion for a strong week', () => {
  const s = blank();
  // Monster week: lots of XP
  const wk = '2026-03-02';
  for (let i = 0; i < 7; i++) {
    const d = addDays(wk, i);
    for (let m = 0; m < 6; m++) s.meals.push(meal(d, 330, 26));
    s.challenges[d] = { metric: 'manual', target: 1, title: 'x', xp: 2000, done: true };
  }
  const stats = computeStats(s, '2026-03-10');
  const league = settleLeague(stats, { tier: 0, week: wk, history: [], baselines: {} }, '2026-03-10');
  assert.equal(league.week, '2026-03-09');
  assert.equal(league.history[0].result, 'promoted');
  assert.equal(league.tier, 1);
  const rows = standings(stats, league, league.week);
  assert.equal(rows.length, 10);
  assert.equal(rows.filter((r) => r.you).length, 1);
});

test('league: idle week does not promote', () => {
  const s = blank();
  const stats = computeStats(s, '2026-03-10');
  const league = settleLeague(stats, { tier: 2, week: '2026-03-02', history: [], baselines: {} }, '2026-03-10');
  assert.equal(league.history[0].result, 'demoted');
  assert.equal(league.tier, 1);
});

test('badges compute', () => {
  const s = blank();
  s.meals.push(meal('2026-03-10', 100));
  const b = earnedBadges(s, computeStats(s, '2026-03-10'));
  assert.equal(b.find((x) => x.id === 'first_bite').earned, true);
  assert.equal(b.find((x) => x.id === 'legend').earned, false);
});
