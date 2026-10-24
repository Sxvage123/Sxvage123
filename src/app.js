// App controller: owns state, derived stats, navigation and the "juice" (XP pops, rank-ups, badges).

import { LocalNotifications } from '@capacitor/local-notifications';
import { Capacitor } from '@capacitor/core';
import { saveState } from './store.js';
import { computeStats, earnedBadges, RANKS } from './lib/game.js';
import { generateChallenge } from './lib/challenges.js';
import { settleLeague, LEAGUES } from './lib/league.js';
import { dayKey, addDays } from './lib/dates.js';
import { computeTargets } from './lib/nutrition.js';
import { xpPop, toast, confetti, haptic, sheet, esc, setHaptics } from './ui/dom.js';
import { rankEmblem } from './ui/charts.js';

export const app = {
  state: null,
  stats: null,
  badges: [],
  today: dayKey(),
  tab: 'home',
  views: {},
  scroll: {},

  init(state, views) {
    this.state = state;
    this.views = views;
    setHaptics(state.settings.haptics);
    this.refresh();
    this.state.seen.tier = Math.max(this.state.seen.tier || 0, this.stats.rank.tier || 0);
    if (!this.state.seen.badges.length) this.state.seen.badges = this.badges.filter((b) => b.earned).map((b) => b.id);
  },

  refresh() {
    this.today = dayKey();
    if (this.state.profile) {
      this.ensureChallenge();
      this.stats = computeStats(this.state, this.today);
      const before = this.state.league;
      this.state.league = settleLeague(this.stats, this.state.league || { tier: 0, week: null, history: [], baselines: {} }, this.today);
      if (before && before.week !== this.state.league.week) this.pendingLeagueResult = this.state.league.history[this.state.league.history.length - 1];
    } else {
      this.stats = computeStats(this.state, this.today);
    }
    this.badges = earnedBadges(this.state, this.stats);
  },

  ensureChallenge() {
    const s = this.state;
    if (s.challenges[this.today]) return;
    const lastScan = [...s.scans].sort((a, b) => b.date.localeCompare(a.date))[0];
    const stats = computeStats(s, this.today);
    s.challenges[this.today] = generateChallenge({
      date: this.today,
      rankIndex: stats.rank.index,
      proteinGoal: s.profile?.proteinGoal,
      lastScanDate: lastScan?.date,
    });
    saveState(s);
  },

  rerollChallenge() {
    const s = this.state;
    const cur = s.challenges[this.today];
    if (!cur || cur.reroll >= 1 || cur.done) return false;
    const lastScan = [...s.scans].sort((a, b) => b.date.localeCompare(a.date))[0];
    s.challenges[this.today] = generateChallenge({
      date: this.today,
      rankIndex: this.stats.rank.index,
      proteinGoal: s.profile?.proteinGoal,
      lastScanDate: lastScan?.date,
      reroll: (cur.reroll || 0) + 1,
    });
    // Rerolling into the same challenge would feel broken; nudge until different.
    let n = 2;
    while (s.challenges[this.today].title === cur.title && n < 6) {
      s.challenges[this.today] = { ...generateChallenge({ date: this.today, rankIndex: this.stats.rank.index, proteinGoal: s.profile?.proteinGoal, reroll: n++ }), reroll: 1 };
    }
    s.challenges[this.today].reroll = 1;
    return true;
  },

  // Mutate state, then recompute everything and celebrate whatever changed.
  update(mutator, { render = true } = {}) {
    const beforeXP = this.stats?.xp || 0;
    mutator(this.state);
    if (this.state.profile && !this.state.profile.customGoals) Object.assign(this.state.profile, targetsFor(this.state.profile));
    this.refresh();
    saveState(this.state);
    const gained = this.stats.xp - beforeXP;
    if (gained) {
      xpPop(gained);
      if (gained > 0) haptic('medium');
    }
    if (render) this.render();
    this.celebrate();
    this.scheduleReminders();
  },

  celebrate() {
    const s = this.state;
    if (!s.profile) return;
    const rank = this.stats.rank;
    if ((rank.tier || 0) > (s.seen.tier || 0)) {
      const bigRank = Math.floor((rank.tier || 0) / 3) > Math.floor((s.seen.tier || 0) / 3);
      s.seen.tier = rank.tier;
      saveState(s);
      showRankUp(rank, bigRank);
    } else if ((rank.tier || 0) < (s.seen.tier || 0)) {
      s.seen.tier = rank.tier; // XP can drop if a meal is deleted; quietly follow.
      saveState(s);
    }
    const fresh = this.badges.filter((b) => b.earned && !s.seen.badges.includes(b.id));
    if (fresh.length) {
      s.seen.badges.push(...fresh.map((b) => b.id));
      saveState(s);
      fresh.forEach((b, i) => setTimeout(() => toast(`Badge unlocked: ${b.name}`, { icon: b.icon, type: 'badge', duration: 3200 }), 600 + i * 900));
    }
    if (this.pendingLeagueResult) {
      const r = this.pendingLeagueResult;
      this.pendingLeagueResult = null;
      setTimeout(() => showLeagueResult(r, this.state.league.tier), 900);
    }
  },

  go(tab) {
    if (this.tab !== tab) {
      this.scroll[this.tab] = document.querySelector('#view')?.scrollTop || 0;
      this.tab = tab;
      haptic('light');
    }
    this.render();
    const v = document.querySelector('#view');
    if (v) v.scrollTop = this.scroll[tab] || 0;
  },

  render() {
    const root = document.querySelector('#app');
    if (!this.state.profile) {
      this.views.onboarding(root, this);
      return;
    }
    if (!document.querySelector('#view')) {
      root.innerHTML = `<main id="view" class="view"></main><nav id="tabbar" class="tabbar"></nav>`;
    }
    const view = document.querySelector('#view');
    const scrollTop = view.scrollTop;
    const fn = this.views[this.tab] || this.views.home;
    view.dataset.tab = this.tab;
    fn(view, this);
    view.scrollTop = scrollTop;
    renderTabbar(this);
  },

  async scheduleReminders() {
    if (!Capacitor.isNativePlatform()) return;
    try {
      await LocalNotifications.cancel({ notifications: [{ id: 1001 }, { id: 1002 }] });
      if (!this.state.settings.reminders || !this.state.profile) return;
      const perm = await LocalNotifications.checkPermissions();
      if (perm.display !== 'granted') return;
      const streak = this.stats.streak;
      const now = new Date();
      const tonight = new Date();
      tonight.setHours(20, 0, 0, 0);
      const notes = [];
      if (!streak.activeToday && tonight > now) {
        notes.push({
          id: 1001,
          title: streak.current > 0 ? `🔥 Your ${streak.current}-day streak is on the line` : '🎯 Your daily challenge is waiting',
          body: streak.current > 0 ? 'Log a meal or finish your challenge before midnight to keep it alive.' : 'Log a meal or crush today’s challenge to start a streak.',
          schedule: { at: tonight, allowWhileIdle: true },
        });
      }
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(9, 0, 0, 0);
      notes.push({ id: 1002, title: '⚔️ New daily challenge unlocked', body: 'A fresh challenge just dropped. Go earn that XP.', schedule: { at: tomorrow, allowWhileIdle: true } });
      await LocalNotifications.schedule({ notifications: notes });
    } catch (e) {
      console.warn('reminders', e);
    }
  },
};

export function targetsFor(profile) {
  const t = computeTargets(profile);
  return { calorieGoal: t.calories, proteinGoal: t.protein, carbsGoal: t.carbs, fatGoal: t.fat, tdee: t.tdee };
}

const TABS = [
  { id: 'home', label: 'Home', icon: '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>' },
  { id: 'food', label: 'Food', icon: '<path d="M7 2v8a3 3 0 0 0 2 2.8V22h2V12.8A3 3 0 0 0 13 10V2h-1.5v6h-1V2h-2v6h-1V2zM17 2c-1.7 0-3 2-3 5v6h2v9h2V2z"/>' },
  { id: 'scan', label: 'Scan', icon: '<path d="M4 4h5V2H2v7h2zm11-2v2h5v5h2V2zM4 15H2v7h7v-2H4zm16 5h-5v2h7v-7h-2zM12 6a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5m-4.5 12c0-2.8 2-4.5 4.5-4.5s4.5 1.7 4.5 4.5z"/>' },
  { id: 'progress', label: 'Ranks', icon: '<path d="M7 21H3v-8h4zm7 0h-4V3h4zm7 0h-4V9h4z"/>' },
  { id: 'me', label: 'Me', icon: '<path d="M12 12a5 5 0 1 0 0-10 5 5 0 0 0 0 10m0 2c-4.4 0-8 2.2-8 5v3h16v-3c0-2.8-3.6-5-8-5"/>' },
];

function renderTabbar(app) {
  const nav = document.querySelector('#tabbar');
  nav.innerHTML = TABS.map(
    (t) => `<button class="tab ${app.tab === t.id ? 'active' : ''} ${t.id === 'scan' ? 'tab-scan' : ''}" data-tab="${t.id}" aria-label="${t.label}">
      <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">${t.icon}</svg><span>${t.label}</span></button>`,
  ).join('');
  nav.querySelectorAll('[data-tab]').forEach((b) => (b.onclick = () => app.go(b.dataset.tab)));
}

function showRankUp(rank, bigRank) {
  haptic('success');
  confetti({ colors: [rank.color, '#ffffff', rank.glow, '#d4ff3a'] });
  sheet(
    (el, close) => {
      el.innerHTML = `
      <div class="rankup">
        <div class="rankup-label">${bigRank ? 'NEW RANK UNLOCKED' : 'DIVISION UP'}</div>
        <div class="rankup-emblem">${rankEmblem(rank, 150)}</div>
        <h1 class="rankup-title" style="color:${rank.color}">${esc(rank.title)}</h1>
        <p class="muted">${rank.nextAt ? `Next: <b>${esc(rank.nextTitle)}</b> at ${rank.nextAt.toLocaleString()} XP` : 'You reached the top. Legend status.'}</p>
        <button class="btn btn-primary btn-block mt" data-ok>Let’s go</button>
      </div>`;
      el.querySelector('[data-ok]').onclick = () => close();
    },
    { className: 'sheet-celebrate' },
  );
}

function showLeagueResult(r, newTier) {
  const league = LEAGUES[newTier];
  const msg = r.result === 'promoted' ? `Promoted to ${league.name}!` : r.result === 'demoted' ? `Demoted to ${league.name}` : `You held your spot in ${league.name}`;
  if (r.result === 'promoted') confetti();
  sheet((el, close) => {
    el.innerHTML = `
      <div class="rankup">
        <div class="rankup-label">LAST WEEK’S LEAGUE</div>
        <div class="league-big">${league.icon}</div>
        <h1 class="rankup-title" style="color:${league.color}">${esc(msg)}</h1>
        <p class="muted">You finished <b>#${r.place}</b> with <b>${r.xp.toLocaleString()} XP</b>.</p>
        <button class="btn btn-primary btn-block mt" data-ok>New week, new grind</button>
      </div>`;
    el.querySelector('[data-ok]').onclick = () => close();
  });
}

export { RANKS, LEAGUES, addDays };
