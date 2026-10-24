// Ranks tab: rank ladder, weekly league, badges, food & weight trends, progress photos.

import { esc, fmt, sheet, toast } from './dom.js';
import { shareRank } from './sharecard.js';
import { lbToKg } from '../lib/nutrition.js';
import { rankEmblem, lineChart, barChart } from './charts.js';
import { RANKS, rankFor, dayTotals } from '../lib/game.js';
import { standings, LEAGUES, weekProgress, PROMOTE, DEMOTE } from '../lib/league.js';
import { addDays, parseDay, shortDay } from '../lib/dates.js';
import { kgToLb } from '../lib/nutrition.js';

let section = 'rank';

export function renderProgress(root, app) {
  const tabs = [
    ['rank', 'Rank'],
    ['league', 'League'],
    ['badges', 'Badges'],
    ['trends', 'Trends'],
  ];
  root.innerHTML = `
    <header class="page-head"><h1 class="h1">Ranks</h1></header>
    <div class="seg seg-4 sticky-seg">${tabs.map(([id, l]) => `<button class="seg-btn ${section === id ? 'active' : ''}" data-sec="${id}">${l}</button>`).join('')}</div>
    <div id="sec"></div>
    <div class="spacer"></div>`;
  root.querySelectorAll('[data-sec]').forEach(
    (b) =>
      (b.onclick = () => {
        section = b.dataset.sec;
        app.render();
      }),
  );
  const sec = root.querySelector('#sec');
  if (section === 'rank') rankSection(sec, app);
  else if (section === 'league') sec.innerHTML = leagueHTML(app);
  else if (section === 'badges') badgeSection(sec, app);
  else trendSection(sec, app);
}

function rankSection(sec, app) {
  const { stats } = app;
  setTimeout(() => sec.querySelector('[data-share]')?.addEventListener('click', () => shareRank(app)));
  const r = stats.rank;
  sec.innerHTML = `
    <section class="card rank-hero" style="--rank:${r.color};--rank-glow:${r.glow}">
      ${rankEmblem(r, 132)}
      <h2 style="color:${r.color}">${esc(r.title)}</h2>
      <div class="muted">Level ${stats.level.level} · ${fmt(stats.xp)} XP</div>
      <div class="xpbar big"><div class="xpbar-fill" style="width:${(r.progress * 100).toFixed(1)}%"></div></div>
      <div class="muted small">${r.nextAt ? `${fmt(r.nextAt - stats.xp)} XP to ${esc(r.nextTitle)}` : 'You are a Legend.'}</div>
      <button class="btn btn-ghost btn-sm mt" data-share>📤 Share my rank</button>
    </section>
    <section class="card">
      <div class="card-head"><h3>Rank ladder</h3></div>
      ${[...RANKS]
        .reverse()
        .map((rk, i) => {
          const idx = RANKS.length - 1 - i;
          const reached = stats.xp >= rk.min;
          const current = idx === r.index;
          const fake = rankFor(rk.min);
          return `<div class="ladder ${reached ? 'reached' : ''} ${current ? 'current' : ''}">
            ${rankEmblem({ ...fake, division: rk.name === 'Legend' ? '' : 'III' }, 42)}
            <div class="grow"><b style="color:${reached ? rk.color : 'inherit'}">${esc(rk.name)}</b><div class="muted tiny">${fmt(rk.min)} XP</div></div>
            ${current ? '<span class="you-tag">YOU</span>' : reached ? '<span class="accent">✓</span>' : '<span class="muted">🔒</span>'}
          </div>`;
        })
        .join('')}
    </section>`;
}

export function leagueHTML(app) {
  const { state, stats } = app;
  const lg = LEAGUES[state.league.tier];
  const rows = standings(stats, state.league, state.league.week, new Date(), state.profile.name);
  const left = 1 - weekProgress(state.league.week);
  const hoursLeft = Math.max(0, Math.round(left * 7 * 24));
  const timeLeft = hoursLeft > 48 ? `${Math.round(hoursLeft / 24)} days` : `${hoursLeft} hours`;
  const hist = (state.league.history || []).slice(-6).reverse();
  return `
    <section class="card league-hero" style="--league:${lg.color}">
      <div class="league-big">${lg.icon}</div>
      <h2 style="color:${lg.color}">${esc(lg.name)}</h2>
      <div class="muted small">${timeLeft} left · Top ${PROMOTE} promote · Bottom ${DEMOTE} demote</div>
      <div class="league-path">${LEAGUES.map((l, i) => `<span class="${i === state.league.tier ? 'cur' : i < state.league.tier ? 'past' : ''}" title="${esc(l.name)}">${l.icon}</span>`).join('')}</div>
    </section>
    <section class="card standings">
      ${rows
        .map(
          (r) => `
        <div class="standing ${r.you ? 'you' : ''} zone-${r.zone}">
          <span class="place">${r.place}</span>
          <span class="avatar" style="background:${r.you ? 'var(--accent)' : avatarColor(r.name)}">${esc(r.name[0])}</span>
          <span class="grow name">${esc(r.name)}</span>
          <b>${fmt(r.xp)} XP</b>
        </div>
        ${r.place === PROMOTE && state.league.tier < LEAGUES.length - 1 ? '<div class="zone-line up">▲ PROMOTION ZONE</div>' : ''}
        ${r.place === rows.length - DEMOTE && state.league.tier > 0 ? '<div class="zone-line down">▼ DEMOTION ZONE</div>' : ''}`,
        )
        .join('')}
    </section>
    ${
      hist.length
        ? `<section class="card"><div class="card-head"><h3>Past weeks</h3></div>${hist
            .map((h) => `<div class="xp-line"><span>${esc(shortDay(h.week))} · ${esc(LEAGUES[h.tier].name)}</span><b class="${h.result === 'promoted' ? 'accent' : h.result === 'demoted' ? 'danger' : ''}">#${h.place} ${h.result === 'promoted' ? '▲' : h.result === 'demoted' ? '▼' : '•'}</b></div>`)
            .join('')}</section>`
        : ''
    }
    <p class="muted tiny center">League rivals are simulated players matched to your recent pace, so every week is a fight.</p>`;
}

export function openLeague(app) {
  sheet((el) => (el.innerHTML = leagueHTML(app)), { full: true });
}

function avatarColor(name) {
  let h = 0;
  for (const c of name) h = (h * 31 + c.charCodeAt(0)) % 360;
  return `hsl(${h} 55% 45%)`;
}

function badgeSection(sec, app) {
  const earned = app.badges.filter((b) => b.earned).length;
  sec.innerHTML = `
    <section class="card">
      <div class="card-head"><h3>Badges</h3><span class="muted small">${earned} / ${app.badges.length}</span></div>
      <div class="badge-grid">
        ${app.badges.map((b) => `<div class="badge ${b.earned ? 'earned' : ''}"><div class="badge-icon">${b.earned ? b.icon : '🔒'}</div><b>${esc(b.name)}</b><small>${esc(b.desc)}</small></div>`).join('')}
      </div>
    </section>`;
}

function trendSection(sec, app) {
  const { state, today } = app;
  const p = state.profile;
  const days = Array.from({ length: 14 }, (_, i) => addDays(today, i - 13));
  const totals = days.map((d) => dayTotals(state, d));
  const logged = totals.filter((t) => t.meals > 0);
  const avg = (k) => (logged.length ? logged.reduce((s, t) => s + t[k], 0) / logged.length : 0);
  const imp = state.settings.units !== 'metric';
  const weights = [...(state.weights || [])].sort((a, b) => a.date.localeCompare(b.date)).slice(-30);
  const photos = [...state.scans].filter((s) => s.thumb).sort((a, b) => a.time.localeCompare(b.time));
  const xpDays = days.map((d) => app.stats.xpByDay.get(d)?.total || 0);
  sec.innerHTML = `
    <section class="card">
      <div class="card-head"><h3>Calories · 14 days</h3></div>
      ${barChart(
        days.map((d, i) => ({
          x: parseDay(d).toLocaleDateString(undefined, { weekday: 'narrow' }),
          y: Math.round(totals[i].calories),
          color: totals[i].calories > p.calorieGoal * 1.1 ? 'var(--danger)' : 'var(--accent)',
        })),
        { goal: p.calorieGoal },
      )}
      <div class="stat-grid">
        <div class="stat"><b>${fmt(avg('calories'))}</b><span>Avg kcal (logged days)</span></div>
        <div class="stat"><b>${fmt(avg('protein'))}g</b><span>Avg protein</span></div>
        <div class="stat"><b>${logged.length}/14</b><span>Days logged</span></div>
        <div class="stat"><b>${fmt(xpDays.reduce((a, b) => a + b, 0))}</b><span>XP · 14 days</span></div>
      </div>
    </section>
    <section class="card">
      <div class="card-head"><h3>XP · 14 days</h3></div>
      ${barChart(days.map((d, i) => ({ x: parseDay(d).toLocaleDateString(undefined, { weekday: 'narrow' }), y: xpDays[i], color: 'var(--violet)' })))}
    </section>
    <section class="card">
      <div class="card-head"><h3>Weight</h3><button class="btn btn-ghost btn-sm" data-weigh>＋ Log weight</button></div>
      ${weights.length >= 2 ? lineChart(weights.map((w) => ({ x: shortDay(w.date), y: imp ? kgToLb(w.kg) : w.kg })), { unit: imp ? ' lb' : ' kg', color: 'var(--blue)' }) : '<p class="muted small">Log your weight a few times a week (mornings are best) to see your trend.</p>'}
    </section>
    ${
      photos.length
        ? `<section class="card"><div class="card-head"><h3>Progress photos</h3><span class="muted small">private · on device</span></div>
          ${photos.length >= 2 ? `<div class="compare"><figure><img src="${esc(photos[0].thumb)}" alt=""/><figcaption>${esc(shortDay(photos[0].date))} · ${fmt(photos[0].bodyFat, 1)}%</figcaption></figure><figure><img src="${esc(photos[photos.length - 1].thumb)}" alt=""/><figcaption>${esc(shortDay(photos[photos.length - 1].date))} · ${fmt(photos[photos.length - 1].bodyFat, 1)}%</figcaption></figure></div>` : ''}
          <div class="gallery">${photos.slice(-12).reverse().map((s) => `<img src="${esc(s.thumb)}" alt=""/>`).join('')}</div></section>`
        : ''
    }`;
  sec.querySelector('[data-weigh]').onclick = () => logWeight(app);
}

export function logWeight(app) {
  const p = app.state.profile;
  const imp = app.state.settings.units !== 'metric';
  sheet((el, close) => {
    el.innerHTML = `
      <h2 class="sheet-title">Log weight</h2>
      <p class="muted small">Same scale, same time of day (right after waking up) gives the cleanest trend.</p>
      <div class="input-unit"><input class="input input-xl" data-w type="number" inputmode="decimal" value="${imp ? Math.round(kgToLb(p.weightKg) * 10) / 10 : p.weightKg}"/><span>${imp ? 'lb' : 'kg'}</span></div>
      <div class="onb-error" data-err></div>
      <button class="btn btn-primary btn-block btn-lg" data-ok>Save</button>`;
    const input = el.querySelector('[data-w]');
    setTimeout(() => input.select(), 60);
    el.querySelector('[data-ok]').onclick = () => {
      const v = Number(input.value);
      const kg = Math.round((imp ? lbToKg(v) : v) * 10) / 10;
      if (!(kg >= 30 && kg <= 300)) {
        el.querySelector('[data-err]').textContent = 'Enter a realistic weight.';
        return;
      }
      app.update((s) => {
        s.profile.weightKg = kg;
        s.weights = [...(s.weights || []).filter((w) => w.date !== app.today), { date: app.today, kg }];
      });
      close();
      toast('Weight logged — targets updated', { icon: '⚖️' });
    };
  });
}
