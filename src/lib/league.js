// Weekly league against simulated rivals. Top 3 promote, bottom 3 demote — like Duolingo,
// but offline. Rivals' XP grows through the week, scaled to your own average so it stays a fight.

import { addDays, weekStart } from './dates.js';
import { seeded } from './rng.js';
import { weekXP } from './game.js';

export const LEAGUES = [
  { name: 'Rookie League', color: '#9aa3ad', icon: '🪨' },
  { name: 'Bronze League', color: '#e0915a', icon: '🥉' },
  { name: 'Silver League', color: '#d5dde6', icon: '🥈' },
  { name: 'Gold League', color: '#ffd34d', icon: '🥇' },
  { name: 'Sapphire League', color: '#6fb6ff', icon: '🔷' },
  { name: 'Ruby League', color: '#ff5d7a', icon: '♦️' },
  { name: 'Obsidian League', color: '#a78bfa', icon: '🖤' },
  { name: 'Apex League', color: '#d4ff3a', icon: '⚜️' },
];

const NAMES = [
  'IronMike', 'GymRatGabe', 'LeanQueen', 'SquatSquad', 'MacroMaya', 'ProteinPete', 'CardioKai', 'BulkBro',
  'ShredSam', 'DeadliftDee', 'RepRiley', 'FitFinn', 'SweatyBetty', 'PlankPrince', 'BeastModeBo', 'KettlebellKim',
  'GainzGuru', 'TofuTitan', 'BurpeeBen', 'CoreCora', 'HustleHank', 'JacqueJacked', 'NoDaysOffNia', 'MealPrepMo',
  'RunnerRae', 'SpartanSol', 'ZeroSugarZoe', 'ChalkHands', 'LiftLuca', 'StepQueenSky', 'GritGrace', 'MaxRepMax',
];

export const PROMOTE = 3;
export const DEMOTE = 3;
const RIVALS = 9;

function rivalsFor(week, tier, baseline) {
  const rand = seeded(`league:${week}:${tier}`);
  const names = [...NAMES];
  const rivals = [];
  for (let i = 0; i < RIVALS; i++) {
    const name = names.splice(Math.floor(rand() * names.length), 1)[0];
    // Skill spread so some rivals are beatable and a couple are monsters.
    // Centred a bit below your recent average so steady grinders climb; a rare "monster" keeps the top spots spicy.
    const skill = 0.28 + rand() * 0.9 + (rand() < 0.12 ? 0.55 : 0);
    const tierBoost = 1 + tier * 0.05;
    rivals.push({ name, final: Math.round(baseline * skill * tierBoost), curve: 0.7 + rand() * 0.6, seed: rand() });
  }
  return rivals;
}

// Fraction of the week elapsed (0..1) at `now`.
export function weekProgress(week, now = new Date()) {
  const [y, m, d] = week.split('-').map(Number);
  const start = new Date(y, m - 1, d).getTime();
  return Math.max(0, Math.min(1, (now.getTime() - start) / (7 * 86400000)));
}

export function baselineXP(stats, week) {
  // Average of your last 3 weeks, with a floor so new players still face real rivals.
  let sum = 0;
  let n = 0;
  for (let i = 1; i <= 3; i++) {
    const w = addDays(week, -7 * i);
    const xp = weekXP(stats, w);
    if (xp > 0) {
      sum += xp;
      n++;
    }
  }
  return Math.max(700, n ? sum / n : 700);
}

export function standings(stats, league, week, now = new Date(), you = 'You') {
  const tier = league.tier;
  // In the week you join, rivals only start scoring from the moment you joined.
  const j = league.joinedAt && weekStartOf(league.joinedAt) === week ? weekProgress(week, new Date(league.joinedAt)) : 0;
  const raw = weekProgress(week, now);
  const t = j >= 1 ? 1 : Math.max(0, (raw - j) / (1 - j));
  const rivals = rivalsFor(week, tier, league.baselines?.[week] ?? baselineXP(stats, week));
  const rows = rivals.map((r) => ({
    name: r.name,
    xp: Math.round(r.final * (1 - j) * Math.pow(t, r.curve) * (0.92 + 0.16 * Math.abs(Math.sin(t * 9 + r.seed * 6)))),
    you: false,
  }));
  rows.push({ name: you, xp: weekXP(stats, week), you: true });
  rows.sort((a, b) => b.xp - a.xp || (a.you ? -1 : 1));
  rows.forEach((r, i) => {
    r.place = i + 1;
    r.zone = i < PROMOTE && tier < LEAGUES.length - 1 ? 'promote' : i >= rows.length - DEMOTE && tier > 0 ? 'demote' : 'safe';
  });
  return rows;
}

// Called on app start: settles any finished weeks and returns the updated league state.
const weekStartOf = (iso) => {
  const d = new Date(iso);
  return weekStart(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`);
};

export function settleLeague(stats, league, today, now = new Date()) {
  const current = weekStart(today);
  const next = { tier: 0, week: current, history: [], baselines: {}, ...league };
  if (!next.week) next.week = current;
  if (!next.joinedAt) next.joinedAt = now.toISOString();
  next.baselines = { ...next.baselines };
  if (!next.baselines[current]) next.baselines[current] = Math.round(baselineXP(stats, current));
  let guard = 0;
  while (next.week < current && guard++ < 60) {
    const rows = standings(stats, next, next.week, new Date(8.64e15));
    const you = rows.find((r) => r.you);
    let result = 'stayed';
    if (you.zone === 'promote') result = 'promoted';
    else if (you.zone === 'demote') result = 'demoted';
    // An empty week (no XP at all) doesn't count as a competitive result.
    if (you.xp === 0 && result === 'promoted') result = 'stayed';
    next.history = [...next.history, { week: next.week, tier: next.tier, place: you.place, xp: you.xp, result }].slice(-52);
    if (result === 'promoted') next.tier = Math.min(LEAGUES.length - 1, next.tier + 1);
    if (result === 'demoted') next.tier = Math.max(0, next.tier - 1);
    next.week = addDays(next.week, 7);
    if (!next.baselines[next.week]) next.baselines[next.week] = Math.round(baselineXP(stats, next.week));
  }
  // Keep the baseline map small.
  for (const k of Object.keys(next.baselines)) if (k < addDays(current, -56)) delete next.baselines[k];
  return next;
}
