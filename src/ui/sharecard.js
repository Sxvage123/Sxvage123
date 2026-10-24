// Renders a shareable "rank card" image and opens the native share sheet.

import { Capacitor } from '@capacitor/core';
import { Filesystem, Directory } from '@capacitor/filesystem';
import { Share } from '@capacitor/share';
import { rankEmblem } from './charts.js';
import { toast, sheet } from './dom.js';
import { weekXP } from '../lib/game.js';
import { weekStart } from '../lib/dates.js';
import { LEAGUES } from '../lib/league.js';

function svgImage(markup, size) {
  return new Promise((resolve, reject) => {
    const svg = markup.replace('<svg ', `<svg xmlns="http://www.w3.org/2000/svg" `).replace(/width="\d+" height="\d+"/, `width="${size}" height="${size}"`);
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
  });
}

export async function renderShareCard(app) {
  const { state, stats } = app;
  const p = state.profile;
  const r = stats.rank;
  const W = 1080;
  const H = 1350;
  const c = document.createElement('canvas');
  c.width = W;
  c.height = H;
  const ctx = c.getContext('2d');
  const g = ctx.createLinearGradient(0, 0, W, H);
  g.addColorStop(0, '#151a24');
  g.addColorStop(1, '#07090d');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, W, H);
  const glow = ctx.createRadialGradient(W / 2, 420, 40, W / 2, 420, 560);
  glow.addColorStop(0, `${r.color}55`);
  glow.addColorStop(1, 'transparent');
  ctx.fillStyle = glow;
  ctx.fillRect(0, 0, W, H);

  const font = (w, s) => `${w} ${s}px system-ui, -apple-system, Roboto, sans-serif`;
  ctx.textAlign = 'center';
  ctx.fillStyle = '#8a93a6';
  ctx.font = font(800, 34);
  ctx.fillText('GRINDFIT', W / 2, 110);

  const emblem = await svgImage(rankEmblem(r, 420), 420);
  ctx.drawImage(emblem, W / 2 - 210, 170, 420, 420);

  ctx.fillStyle = r.color;
  ctx.font = font(900, 96);
  ctx.fillText(r.title, W / 2, 700);
  ctx.fillStyle = '#f1f4f9';
  ctx.font = font(800, 54);
  ctx.fillText(p.name, W / 2, 780);
  ctx.fillStyle = '#8a93a6';
  ctx.font = font(600, 36);
  ctx.fillText(`Level ${stats.level.level} · ${stats.xp.toLocaleString()} XP`, W / 2, 836);

  const scans = [...state.scans].sort((a, b) => a.time.localeCompare(b.time));
  const tiles = [
    ['🔥', `${stats.streak.current}`, 'day streak'],
    ['⚔️', `${stats.challengesDone}`, 'challenges'],
    [LEAGUES[state.league.tier].icon, `${weekXP(stats, weekStart(app.today)).toLocaleString()}`, 'XP this week'],
  ];
  if (scans.length >= 2) {
    const first = scans[0];
    const drop = Math.min(...scans.filter((s) => s.date === first.date).map((s) => s.bodyFat)) - scans[scans.length - 1].bodyFat;
    if (drop > 0) tiles[2] = ['📉', `−${drop.toFixed(1)}%`, 'body fat'];
  }
  const tw = 300;
  const gap = 30;
  const x0 = (W - (tw * 3 + gap * 2)) / 2;
  tiles.forEach(([icon, big, small], i) => {
    const x = x0 + i * (tw + gap);
    const y = 920;
    ctx.fillStyle = '#151922';
    ctx.strokeStyle = '#262c3b';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.roundRect(x, y, tw, 250, 36);
    ctx.fill();
    ctx.stroke();
    ctx.font = font(400, 56);
    ctx.fillText(icon, x + tw / 2, y + 80);
    ctx.fillStyle = '#d4ff3a';
    ctx.font = font(900, 64);
    ctx.fillText(big, x + tw / 2, y + 165);
    ctx.fillStyle = '#8a93a6';
    ctx.font = font(700, 30);
    ctx.fillText(small, x + tw / 2, y + 215);
    ctx.fillStyle = '#f1f4f9';
  });
  ctx.fillStyle = '#5b6375';
  ctx.font = font(700, 30);
  ctx.fillText('Track. Scan. Rank up.', W / 2, 1270);
  return c;
}

export async function shareRank(app) {
  let canvas;
  try {
    canvas = await renderShareCard(app);
  } catch (e) {
    toast(`Couldn’t make the card: ${e.message || e}`, { type: 'error' });
    return;
  }
  const dataUrl = canvas.toDataURL('image/png');
  if (Capacitor.isNativePlatform()) {
    try {
      const file = await Filesystem.writeFile({ path: `grindfit-rank-${Date.now()}.png`, data: dataUrl.split(',')[1], directory: Directory.Cache });
      await Share.share({ title: 'My GrindFit rank', text: `I'm ${app.stats.rank.title} on GrindFit 💪`, files: [file.uri], dialogTitle: 'Share your rank' });
    } catch (e) {
      if (!String(e?.message || e).toLowerCase().includes('cancel')) toast(`Share failed: ${e.message || e}`, { type: 'error' });
    }
    return;
  }
  // Web fallback: preview + download.
  sheet((el) => {
    el.innerHTML = `<img src="${dataUrl}" style="width:100%;border-radius:18px" alt="Rank card"/><a class="btn btn-primary btn-block" download="grindfit-rank.png" href="${dataUrl}">Download image</a>`;
  });
}
