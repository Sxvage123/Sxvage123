// Persistent app state. Uses Capacitor Preferences (native SharedPreferences on Android,
// localStorage on web). Everything stays on the device.

import { Preferences } from '@capacitor/preferences';

const KEY = 'grindfit.state.v1';
export const STATE_VERSION = 1;

export function emptyState() {
  return {
    version: STATE_VERSION,
    profile: null,
    meals: [],
    scans: [],
    challenges: {},
    league: null,
    favorites: [],
    custom: [], // user-created foods
    settings: { reminders: true, haptics: true, units: 'imperial' },
    seen: { tier: 0, badges: [], leagueWeek: null },
    weights: [], // [{date, kg}]
    createdAt: new Date().toISOString(),
  };
}

function migrate(s) {
  const base = emptyState();
  return {
    ...base,
    ...s,
    settings: { ...base.settings, ...(s.settings || {}) },
    seen: { ...base.seen, ...(s.seen || {}) },
  };
}

export async function loadState() {
  try {
    const { value } = await Preferences.get({ key: KEY });
    if (value) return migrate(JSON.parse(value));
  } catch (e) {
    console.error('Failed to load state', e);
  }
  return emptyState();
}

let saveTimer = null;
let pending = null;
export function saveState(state) {
  pending = state;
  clearTimeout(saveTimer);
  saveTimer = setTimeout(flush, 150);
}

export async function flush() {
  clearTimeout(saveTimer);
  if (!pending) return;
  const s = pending;
  pending = null;
  try {
    await Preferences.set({ key: KEY, value: JSON.stringify(s) });
  } catch (e) {
    console.error('Failed to save state', e);
  }
}

export function exportJSON(state) {
  return JSON.stringify({ app: 'grindfit', exportedAt: new Date().toISOString(), state }, null, 1);
}

const isImage = (v) =>
  typeof v === 'string' &&
  (/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/.test(v) || /^https?:\/\/localhost\/_capacitor_file_\/[\w./-]+\.jpg$/.test(v));
const num = (v) => (typeof v === 'number' && isFinite(v) ? v : 0);
const str = (v, max = 120) => (typeof v === 'string' ? v.slice(0, max) : '');

// Backups can come from anywhere: keep only well-formed fields so nothing executable sneaks into the UI.
export function sanitizeState(s) {
  const clean = migrate(s);
  clean.meals = (s.meals || []).filter((m) => m && typeof m.date === 'string').map((m) => ({
    ...m,
    id: str(m.id, 40) || uid(),
    name: str(m.name, 80),
    date: str(m.date, 10),
    time: str(m.time, 40),
    loggedOn: m.loggedOn ? str(m.loggedOn, 10) : undefined,
    calories: num(m.calories), protein: num(m.protein), carbs: num(m.carbs), fat: num(m.fat),
    thumb: isImage(m.thumb) ? m.thumb : null,
  }));
  clean.scans = (s.scans || []).filter((x) => x && typeof x.date === 'string' && typeof x.bodyFat === 'number').map((x) => ({
    ...x,
    id: str(x.id, 40) || uid(),
    date: str(x.date, 10),
    time: str(x.time, 40),
    method: str(x.method, 20),
    bodyFat: num(x.bodyFat), low: num(x.low), high: num(x.high),
    thumb: isImage(x.thumb) ? x.thumb : null,
    warnings: Array.isArray(x.warnings) ? x.warnings.map((w) => str(w, 20)) : [],
  }));
  const ch = {};
  for (const [d, c] of Object.entries(s.challenges || {})) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(d) || !c) continue;
    ch[d] = { ...c, title: str(c.title), description: str(c.description, 300), icon: str(c.icon, 8), metric: str(c.metric, 30), difficulty: ['easy', 'medium', 'hard'].includes(c.difficulty) ? c.difficulty : 'medium', xp: Math.min(400, num(c.xp)), target: num(c.target) || 1 };
  }
  clean.challenges = ch;
  if (clean.profile) clean.profile = { ...clean.profile, name: str(clean.profile.name, 24) };
  return clean;
}

export function importJSON(text) {
  const data = JSON.parse(text);
  const s = data.state || data;
  if (!s || !Array.isArray(s.meals) || !Array.isArray(s.scans)) throw new Error('That file is not a GrindFit backup.');
  return sanitizeState(s);
}

export const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
