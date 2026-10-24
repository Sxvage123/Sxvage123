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

export function importJSON(text) {
  const data = JSON.parse(text);
  const s = data.state || data;
  if (!s || !Array.isArray(s.meals) || !Array.isArray(s.scans)) throw new Error('That file is not a GrindFit backup.');
  return migrate(s);
}

export const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
