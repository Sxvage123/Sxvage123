// Lightweight SVG charts + the rank emblem. No chart library needed.

import { esc } from './dom.js';

const W = 340;

// points: [{x: label, y: number, lo?, hi?}] in chronological order
export function lineChart(points, { height = 170, color = 'var(--accent)', unit = '', band = true, goal = null, decimals = 1 } = {}) {
  if (points.length === 0) return '<div class="chart-empty">No data yet</div>';
  const pad = { l: 34, r: 12, t: 14, b: 26 };
  const ys = points.flatMap((p) => [p.y, p.lo ?? p.y, p.hi ?? p.y]);
  if (goal !== null) ys.push(goal);
  let min = Math.min(...ys);
  let max = Math.max(...ys);
  if (max - min < 2) {
    min -= 1;
    max += 1;
  }
  const span = max - min;
  min -= span * 0.1;
  max += span * 0.1;
  const iw = W - pad.l - pad.r;
  const ih = height - pad.t - pad.b;
  const X = (i) => pad.l + (points.length === 1 ? iw / 2 : (i / (points.length - 1)) * iw);
  const Y = (v) => pad.t + (1 - (v - min) / (max - min)) * ih;
  const path = points.map((p, i) => `${i ? 'L' : 'M'}${X(i).toFixed(1)},${Y(p.y).toFixed(1)}`).join('');
  const area = `${path}L${X(points.length - 1).toFixed(1)},${pad.t + ih}L${X(0).toFixed(1)},${pad.t + ih}Z`;
  let bandPath = '';
  if (band && points.some((p) => p.lo !== undefined)) {
    const top = points.map((p, i) => `${i ? 'L' : 'M'}${X(i).toFixed(1)},${Y(p.hi ?? p.y).toFixed(1)}`).join('');
    const bottom = [...points].reverse().map((p, j) => `L${X(points.length - 1 - j).toFixed(1)},${Y(p.lo ?? p.y).toFixed(1)}`).join('');
    bandPath = `<path d="${top}${bottom}Z" fill="${color}" opacity="0.12"/>`;
  }
  const ticks = [min + (max - min) * 0.15, (min + max) / 2, max - (max - min) * 0.15];
  const labelIdx = points.length <= 6 ? points.map((_, i) => i) : [0, Math.floor((points.length - 1) / 2), points.length - 1];
  const gid = `g${Math.random().toString(36).slice(2, 7)}`;
  return `
  <svg class="chart" viewBox="0 0 ${W} ${height}" preserveAspectRatio="none" role="img">
    <defs><linearGradient id="${gid}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${color}" stop-opacity="0.35"/><stop offset="1" stop-color="${color}" stop-opacity="0"/>
    </linearGradient></defs>
    ${ticks.map((t) => `<line x1="${pad.l}" x2="${W - pad.r}" y1="${Y(t)}" y2="${Y(t)}" class="grid"/><text x="${pad.l - 6}" y="${Y(t) + 4}" class="axis" text-anchor="end">${t.toFixed(decimals > 0 && span < 10 ? 1 : 0)}</text>`).join('')}
    ${goal !== null ? `<line x1="${pad.l}" x2="${W - pad.r}" y1="${Y(goal)}" y2="${Y(goal)}" class="goal-line"/>` : ''}
    ${bandPath}
    <path d="${area}" fill="url(#${gid})"/>
    <path d="${path}" fill="none" stroke="${color}" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
    ${points.map((p, i) => `<circle cx="${X(i)}" cy="${Y(p.y)}" r="${i === points.length - 1 ? 5 : 3}" fill="${i === points.length - 1 ? color : 'var(--bg)'}" stroke="${color}" stroke-width="2"/>`).join('')}
    ${labelIdx.map((i) => `<text x="${X(i)}" y="${height - 6}" class="axis" text-anchor="${i === 0 && points.length > 1 ? 'start' : i === points.length - 1 && points.length > 1 ? 'end' : 'middle'}">${esc(points[i].x)}</text>`).join('')}
    <text x="${X(points.length - 1)}" y="${Y(points[points.length - 1].y) - 10}" class="value-label" text-anchor="end">${points[points.length - 1].y.toFixed(decimals)}${esc(unit)}</text>
  </svg>`;
}

// bars: [{x: label, y: number, color?}]
export function barChart(bars, { height = 160, goal = null, color = 'var(--accent)' } = {}) {
  if (!bars.length) return '<div class="chart-empty">No data yet</div>';
  const pad = { l: 8, r: 8, t: 14, b: 22 };
  const max = Math.max(goal || 0, ...bars.map((b) => b.y)) * 1.12 || 1;
  const iw = W - pad.l - pad.r;
  const ih = height - pad.t - pad.b;
  const bw = iw / bars.length;
  const Y = (v) => pad.t + (1 - v / max) * ih;
  return `
  <svg class="chart" viewBox="0 0 ${W} ${height}" preserveAspectRatio="none" role="img">
    ${bars
      .map((b, i) => {
        const h = Math.max(b.y > 0 ? 3 : 0, (b.y / max) * ih);
        const x = pad.l + i * bw + bw * 0.18;
        return `<rect x="${x.toFixed(1)}" y="${(pad.t + ih - h).toFixed(1)}" width="${(bw * 0.64).toFixed(1)}" height="${h.toFixed(1)}" rx="3" fill="${b.color || color}" opacity="${b.y ? 1 : 0.25}"/>
        <text x="${(x + bw * 0.32).toFixed(1)}" y="${height - 6}" class="axis" text-anchor="middle">${esc(b.x)}</text>`;
      })
      .join('')}
    ${goal ? `<line x1="${pad.l}" x2="${W - pad.r}" y1="${Y(goal)}" y2="${Y(goal)}" class="goal-line"/><text x="${W - pad.r}" y="${Y(goal) - 4}" class="axis" text-anchor="end">goal</text>` : ''}
  </svg>`;
}

// Shield emblem coloured by rank, with division pips.
export function rankEmblem(rank, size = 72) {
  const id = `e${rank.index}${Math.random().toString(36).slice(2, 6)}`;
  const legend = !rank.division;
  return `
  <svg class="emblem" width="${size}" height="${size}" viewBox="0 0 100 100" aria-label="${esc(rank.title)}">
    <defs>
      <linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="${rank.color}"/><stop offset="1" stop-color="${rank.glow}"/>
      </linearGradient>
      <filter id="${id}f"><feGaussianBlur stdDeviation="3"/></filter>
    </defs>
    <path d="M50 6 L86 20 L82 58 Q78 80 50 94 Q22 80 18 58 L14 20 Z" fill="${rank.glow}" opacity="0.55" filter="url(#${id}f)"/>
    <path d="M50 8 L84 21 L80 57 Q76 78 50 91 Q24 78 20 57 L16 21 Z" fill="url(#${id})" stroke="rgba(255,255,255,0.55)" stroke-width="2"/>
    <path d="M50 18 L74 27 L71 55 Q68 70 50 80 Q32 70 29 55 L26 27 Z" fill="rgba(0,0,0,0.28)"/>
    ${
      legend
        ? '<path d="M50 30 L56 44 L71 45 L59 54 L63 69 L50 61 L37 69 L41 54 L29 45 L44 44 Z" fill="#fff"/>'
        : `<text x="50" y="55" text-anchor="middle" font-size="27" font-weight="900" fill="#fff" font-family="system-ui">${rank.name[0]}</text>
           <text x="50" y="71" text-anchor="middle" font-size="11" font-weight="900" fill="#fff" fill-opacity="0.85" letter-spacing="1.5" font-family="system-ui">${rank.division}</text>`
    }
  </svg>`;
}
