// Home: rank, streak, today's challenge, quests, calorie ring, league snapshot.

import { esc, fmt, ring, bar, confirmDialog, haptic, toast, sheet } from './dom.js';
import { rankEmblem } from './charts.js';
import { dayTotals, dailyQuests, challengeProgress, streakMultiplier } from '../lib/game.js';
import { standings, LEAGUES, weekProgress } from '../lib/league.js';
import { openAddFood } from './food.js';
import { openLeague } from './progress.js';
import { suggestFoods } from '../lib/suggest.js';

export function renderHome(root, app) {
  const { state, stats, today } = app;
  const p = state.profile;
  const rank = stats.rank;
  const t = dayTotals(state, today);
  const quests = dailyQuests(state, today);
  const ch = challengeProgress(state, today);
  const dx = stats.xpByDay.get(today);
  const streak = stats.streak;
  const remaining = p.calorieGoal - Math.round(t.calories);
  const league = state.league;
  const lg = LEAGUES[league.tier];
  const rows = standings(stats, league, league.week, new Date(), state.profile.name);
  const me = rows.find((r) => r.you);
  const daysLeft = Math.max(0, Math.ceil(7 * (1 - weekProgress(league.week))));
  const hour = new Date().getHours();
  const greet = hour < 5 ? 'Late-night grind' : hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  root.innerHTML = `
  <header class="home-head">
    <div>
      <div class="muted small">${greet},</div>
      <h1 class="h1">${esc(p.name)}</h1>
    </div>
    <button aria-label="Streak details" class="streak-chip ${streak.activeToday ? 'lit' : streak.current ? 'risk' : ''}" data-streak>
      <span class="flame">🔥</span><b>${streak.current}</b>
      ${streak.freezes ? `<span class="freeze" title="Streak freezes">🧊${streak.freezes}</span>` : ''}
    </button>
  </header>

  <section class="card rank-card" data-go="progress" role="button" tabindex="0" aria-label="Open ranks" style="--rank:${rank.color};--rank-glow:${rank.glow}">
    <div class="rank-emblem">${rankEmblem(rank, 84)}</div>
    <div class="rank-info">
      <div class="rank-title">${esc(rank.title)}</div>
      <div class="muted small">Level ${stats.level.level} · ${fmt(stats.xp)} XP total</div>
      <div class="xpbar"><div class="xpbar-fill" style="width:${(rank.progress * 100).toFixed(1)}%"></div></div>
      <div class="muted tiny">${rank.nextAt ? `${fmt(rank.nextAt - stats.xp)} XP to <b>${esc(rank.nextTitle)}</b>` : 'Max rank reached'}</div>
    </div>
  </section>

  ${
    streak.atRisk
      ? `<div class="banner banner-risk">🔥 Your <b>${streak.current}-day streak</b> ends at midnight. Log a meal or finish the challenge to keep it.${streak.freezes ? ` (You have ${streak.freezes} freeze${streak.freezes > 1 ? 's' : ''} banked.)` : ''}</div>`
      : ''
  }

  ${ch ? challengeCard(ch) : ''}

  <section class="card today-card">
    <div class="today-ring" data-go="food" role="button" tabindex="0" aria-label="Open food log">
      ${ring({ value: t.calories, max: p.calorieGoal, size: 148, stroke: 13, children: `<div class="ring-num">${fmt(Math.abs(remaining))}</div><div class="ring-label">${remaining >= 0 ? 'kcal left' : 'kcal over'}</div>` })}
    </div>
    <div class="today-macros">
      ${macroRow('Protein', t.protein, p.proteinGoal, 'var(--protein)')}
      ${macroRow('Carbs', t.carbs, p.carbsGoal, 'var(--carbs)')}
      ${macroRow('Fat', t.fat, p.fatGoal, 'var(--fat)')}
      <div class="muted tiny">${fmt(t.calories)} / ${fmt(p.calorieGoal)} kcal eaten</div>
    </div>
  </section>

  <div class="quick-actions">
    <button class="qa" data-add="snap"><span>📸</span>Snap meal</button>
    <button class="qa" data-add="search"><span>🔎</span>Search</button>
    <button class="qa" data-add="barcode"><span>▥</span>Barcode</button>
    <button class="qa" data-go="scan"><span>🧬</span>Body scan</button>
  </div>

  ${macroCloser(app, t)}

  <section class="card">
    <div class="card-head"><h3>Daily quests</h3><span class="muted small">auto-tracked</span></div>
    ${quests
      .map(
        (q) => `
      <div class="quest ${q.done ? 'done' : ''}">
        <div class="check">${q.done ? '✓' : ''}</div>
        <div class="grow">
          <div class="quest-title">${esc(q.title)}</div>
          ${q.done ? '' : `<div class="quest-sub">${q.hint ? esc(q.hint) : `${fmt(q.current)} / ${fmt(q.target)}`}</div>`}
        </div>
        <div class="xp-pill ${q.done ? 'earned' : ''}">+${q.xp}</div>
      </div>`,
      )
      .join('')}
  </section>

  <section class="card league-mini" data-league role="button" tabindex="0" aria-label="Open weekly league" style="--league:${lg.color}">
    <div class="league-icon">${lg.icon}</div>
    <div class="grow">
      <div class="league-name">${esc(lg.name)}</div>
      <div class="muted small">You’re <b>#${me.place}</b> of ${rows.length} · ${fmt(me.xp)} XP this week · ${daysLeft}d left</div>
    </div>
    <div class="zone zone-${me.zone}">${me.zone === 'promote' ? '▲' : me.zone === 'demote' ? '▼' : '•'}</div>
  </section>

  <section class="card">
    <div class="card-head"><h3>Today’s XP</h3><b class="accent">+${fmt(dx?.total || 0)}</b></div>
    ${
      dx && dx.items.length
        ? dx.items.map((i) => `<div class="xp-line"><span>${esc(i.label)}</span><b>+${fmt(i.xp)}</b></div>`).join('')
        : '<p class="muted small">Nothing yet. Log your first meal to get on the board.</p>'
    }
    ${streak.current > 1 ? `<p class="muted tiny mt">Streak bonus is ×${streakMultiplier(streak.current).toFixed(2)} today. Keep it going to reach ×1.50.</p>` : ''}
  </section>
  <div class="spacer"></div>`;

  root.querySelectorAll('[data-go]').forEach((el) => (el.onclick = () => app.go(el.dataset.go)));
  root.querySelectorAll('[data-add]').forEach((el) => (el.onclick = () => openAddFood(app, el.dataset.add)));
  root.querySelector('[data-league]').onclick = () => openLeague(app);
  root.querySelectorAll('[data-suggest]').forEach((el) => (el.onclick = () => openAddFood(app, 'search', { foodName: el.dataset.suggest })));
  root.querySelector('[data-streak]').onclick = () => streakSheet(app);
  bindChallenge(root, app);
}

// Afternoon/evening helper: foods that would close today's calorie and protein gap.
function macroCloser(app, t) {
  const p = app.state.profile;
  const kcalLeft = p.calorieGoal - t.calories;
  const proteinLeft = p.proteinGoal - t.protein;
  const hour = new Date().getHours();
  if (kcalLeft < 150 || (hour < 13 && t.calories < p.calorieGoal * 0.4)) return '';
  const picks = suggestFoods(kcalLeft, proteinLeft);
  if (!picks.length) return '';
  return `
  <section class="card closer">
    <div class="card-head"><h3>🎯 Close your macros</h3><span class="muted small">${fmt(kcalLeft)} kcal${proteinLeft > 0 ? ` · ${fmt(proteinLeft)}g protein` : ''} left</span></div>
    <div class="closer-list">
      ${picks.map((f) => `<button class="closer-item" data-suggest="${esc(f.name)}"><b>${esc(f.name)}</b><span>${fmt(f.calories)} kcal · ${fmt(f.protein)}g P</span></button>`).join('')}
    </div>
  </section>`;
}

function macroRow(label, value, goal, color) {
  return `<div class="macro-row"><div class="macro-label"><span>${label}</span><b>${fmt(value)}<small>/${fmt(goal)}g</small></b></div>${bar(value, goal, color)}</div>`;
}

function challengeCard(ch) {
  return `
  <section class="card challenge ${ch.done ? 'done' : ''} ${ch.boss ? 'boss' : ''}">
    <div class="challenge-top">
      <span class="tag">${ch.boss ? '☠️ SUNDAY BOSS' : '⚔️ DAILY CHALLENGE'}</span>
      <span class="diff diff-${esc(ch.difficulty)}">${esc(ch.difficulty)}</span>
      <span class="xp-pill ${ch.done ? 'earned' : ''}">+${fmt(ch.xp)} XP</span>
    </div>
    <div class="challenge-main">
      <div class="challenge-icon">${esc(ch.icon || '🎯')}</div>
      <div class="grow">
        <h2 class="challenge-title">${esc(ch.title)}</h2>
        <p class="muted small">${esc(ch.description)}</p>
      </div>
    </div>
    ${ch.auto && ch.target > 1 ? `<div class="challenge-progress">${bar(ch.current, ch.target, 'var(--accent)')}<span class="tiny muted">${fmt(ch.current)} / ${fmt(ch.target)}</span></div>` : ''}
    <div class="row gap mt">
      ${
        ch.done
          ? `<div class="done-label grow">✅ Completed${ch.auto ? '' : ' — nice work'}</div>${!ch.auto ? '<button class="btn btn-ghost btn-sm" data-undo>Undo</button>' : ''}`
          : `${ch.auto ? `<div class="muted small grow">${ch.metric === 'body_scan' ? 'Do a body scan to complete' : 'Auto-completes from your food log'}</div>` : '<button class="btn btn-primary grow" data-complete>Mark complete</button>'}
             ${ch.reroll < 1 ? '<button class="btn btn-ghost btn-sm" data-reroll title="Swap challenge (1/day)">🎲 Swap</button>' : ''}
             ${ch.metric === 'body_scan' ? '<button class="btn btn-primary btn-sm" data-go-scan>Scan</button>' : ''}`
      }
    </div>
  </section>`;
}

function bindChallenge(root, app) {
  root.querySelector('[data-complete]')?.addEventListener('click', async () => {
    const ok = await confirmDialog({ title: 'Challenge complete?', message: 'Honor system — only claim it if you actually did it. Your rank means more when it’s real.', confirm: 'I did it 💪' });
    if (!ok) return;
    haptic('success');
    app.update((s) => {
      s.challenges[app.today] = { ...s.challenges[app.today], done: true, doneAt: new Date().toISOString() };
    });
  });
  root.querySelector('[data-undo]')?.addEventListener('click', () =>
    app.update((s) => {
      s.challenges[app.today] = { ...s.challenges[app.today], done: false, doneAt: null };
    }),
  );
  root.querySelector('[data-reroll]')?.addEventListener('click', async () => {
    const ok = await confirmDialog({ title: 'Swap today’s challenge?', message: 'You get one swap per day. The new challenge is random.', confirm: '🎲 Swap it' });
    if (!ok) return;
    app.update(() => app.rerollChallenge());
    toast('New challenge rolled', { icon: '🎲' });
  });
  root.querySelector('[data-go-scan]')?.addEventListener('click', () => app.go('scan'));
}

function streakSheet(app) {
  const s = app.stats.streak;
  sheet((el, close) => {
    el.innerHTML = `
      <div class="center">
        <div class="streak-big">🔥</div>
        <h2 class="sheet-title">${s.current}-day streak</h2>
        <p class="muted">Best: ${s.best} days · Multiplier ×${streakMultiplier(s.current).toFixed(2)}</p>
      </div>
      <div class="card mt">
        <div class="xp-line"><span>🧊 Streak freezes banked</span><b>${s.freezes} / 2</b></div>
        <p class="muted small">Every 7 active days in a row earns a freeze. If you miss a day, a freeze is used automatically so your streak survives.</p>
      </div>
      <div class="card">
        <p class="muted small">A day counts as active when you log a meal, do a body scan or complete the daily challenge. Each streak day adds +5% XP (max +50%).</p>
      </div>
      <button class="btn btn-primary btn-block" data-ok>Got it</button>`;
    el.querySelector('[data-ok]').onclick = () => close();
  });
}
