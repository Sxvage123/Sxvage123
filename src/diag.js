// Tiny on-device error log so problems on a real phone can be shared and fixed.

import { Preferences } from '@capacitor/preferences';
import { Capacitor } from '@capacitor/core';
import { APP_VERSION } from './version.js';

const KEY = 'grindfit.diag.v1';
const MAX = 60;
let entries = [];
let saveTimer = null;

function persist() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => Preferences.set({ key: KEY, value: JSON.stringify(entries) }).catch(() => {}), 500);
}

export function logDiag(kind, message, extra = '') {
  const text = String(message?.stack || message?.message || message).slice(0, 800);
  entries.push({ t: new Date().toISOString(), kind, text, extra: String(extra).slice(0, 300) });
  if (entries.length > MAX) entries = entries.slice(-MAX);
  persist();
}

export async function initDiag() {
  try {
    const { value } = await Preferences.get({ key: KEY });
    if (value) entries = JSON.parse(value);
  } catch {
    entries = [];
  }
  window.addEventListener('error', (e) => logDiag('error', e.error || e.message, `${e.filename || ''}:${e.lineno || ''}`));
  window.addEventListener('unhandledrejection', (e) => logDiag('promise', e.reason));
  const orig = console.error.bind(console);
  console.error = (...args) => {
    logDiag('console', args.map((a) => (a instanceof Error ? a.stack || a.message : typeof a === 'string' ? a : JSON.stringify(a))).join(' '));
    orig(...args);
  };
}

export function diagReport() {
  const head = [
    `GrindFit ${APP_VERSION} · ${Capacitor.getPlatform()}`,
    `UA: ${navigator.userAgent}`,
    `WebAssembly: ${typeof WebAssembly === 'object' ? 'yes' : 'no'} · WebGL2: ${!!document.createElement('canvas').getContext('webgl2')}`,
    `Screen: ${screen.width}×${screen.height} @${devicePixelRatio}`,
    '',
  ];
  const body = entries.length ? entries.map((e) => `[${e.t}] ${e.kind}: ${e.text}${e.extra ? ` (${e.extra})` : ''}`) : ['No errors recorded. 🎉'];
  return [...head, ...body].join('\n');
}

export function clearDiag() {
  entries = [];
  persist();
}

export const diagCount = () => entries.length;
