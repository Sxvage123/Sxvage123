// Date helpers. All app data is keyed by the user's local calendar day ("YYYY-MM-DD").

const pad = (n) => String(n).padStart(2, '0');

export function dayKey(date = new Date()) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function parseDay(key) {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(y, m - 1, d);
}

export function addDays(key, n) {
  const d = parseDay(key);
  d.setDate(d.getDate() + n);
  return dayKey(d);
}

export function daysBetween(a, b) {
  // Whole calendar days from a to b (b - a). Uses UTC to dodge DST shifts.
  const [ay, am, ad] = a.split('-').map(Number);
  const [by, bm, bd] = b.split('-').map(Number);
  return Math.round((Date.UTC(by, bm - 1, bd) - Date.UTC(ay, am - 1, ad)) / 86400000);
}

// Weeks start on Monday, like most fitness leagues.
export function weekStart(key) {
  const d = parseDay(key);
  const dow = (d.getDay() + 6) % 7; // Mon=0 … Sun=6
  d.setDate(d.getDate() - dow);
  return dayKey(d);
}

export function weekDays(startKey) {
  return Array.from({ length: 7 }, (_, i) => addDays(startKey, i));
}

export function formatDay(key, today = dayKey()) {
  const diff = daysBetween(key, today);
  if (diff === 0) return 'Today';
  if (diff === 1) return 'Yesterday';
  if (diff === -1) return 'Tomorrow';
  return parseDay(key).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
}

export function shortDay(key) {
  return parseDay(key).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}
