// Me tab: profile, goals, settings, backup/restore, about.

import { Capacitor } from '@capacitor/core';
import { LocalNotifications } from '@capacitor/local-notifications';
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';
import { Share } from '@capacitor/share';
import { esc, fmt, sheet, toast, confirmDialog, setHaptics } from './dom.js';
import { rankEmblem } from './charts.js';
import { ACTIVITY_LEVELS, GOALS, kgToLb, lbToKg, cmToFtIn, inToCm, bmi } from '../lib/nutrition.js';
import { targetsFor } from '../app.js';
import { showGuide } from './onboarding.js';
import { APP_VERSION } from '../version.js';
import { exportJSON, importJSON, emptyState, flush, saveState } from '../store.js';

export function renderMe(root, app) {
  const { state, stats } = app;
  const p = state.profile;
  const imp = state.settings.units !== 'metric';
  const h = imp ? (() => { const { ft, inch } = cmToFtIn(p.heightCm); return `${ft}′${inch}″`; })() : `${fmt(p.heightCm)} cm`;
  const w = imp ? `${fmt(kgToLb(p.weightKg), 1)} lb` : `${fmt(p.weightKg, 1)} kg`;
  root.innerHTML = `
  <header class="page-head"><h1 class="h1">Me</h1></header>
  <section class="card profile-card">
    ${rankEmblem(stats.rank, 64)}
    <div class="grow">
      <h2>${esc(p.name)}</h2>
      <div class="muted small">${esc(stats.rank.title)} · Lv ${stats.level.level} · ${fmt(stats.xp)} XP</div>
      <div class="muted tiny">Best streak ${stats.streak.best}d · ${state.meals.length} meals · ${state.scans.length} scans</div>
    </div>
  </section>

  <section class="card list">
    <div class="list-head">Profile</div>
    <button class="list-row" data-edit="profile"><span>Body stats</span><span class="muted">${esc(p.sex === 'female' ? '♀' : '♂')} ${p.age}y · ${esc(h)} · ${esc(w)} ›</span></button>
    <button class="list-row" data-edit="goal"><span>Goal & activity</span><span class="muted">${esc(GOALS[p.goal].label)} · ${esc(ACTIVITY_LEVELS.find((a) => a.value === p.activity)?.label || '')} ›</span></button>
    <button class="list-row" data-edit="targets"><span>Daily targets</span><span class="muted">${fmt(p.calorieGoal)} kcal · ${p.proteinGoal}g P${p.customGoals ? ' · custom' : ''} ›</span></button>
    <div class="list-row static"><span>BMI</span><span class="muted">${fmt(bmi(p.weightKg, p.heightCm), 1)}</span></div>
    <div class="list-row static"><span>Maintenance burn</span><span class="muted">${fmt(p.tdee)} kcal/day</span></div>
    ${p.calibration && p.calibration !== 1 ? `<div class="list-row static"><span>Photo scan calibration</span><span class="muted">×${p.calibration.toFixed(2)} <button class="link-btn" data-reset-cal>reset</button></span></div>` : ''}
  </section>

  <section class="card list">
    <div class="list-head">Settings</div>
    <label class="list-row"><span>Units</span>
      <select class="select" data-units><option value="imperial" ${imp ? 'selected' : ''}>ft / lb</option><option value="metric" ${!imp ? 'selected' : ''}>cm / kg</option></select></label>
    <label class="list-row"><span>Streak reminders</span><input type="checkbox" class="switch" data-reminders ${state.settings.reminders ? 'checked' : ''}/></label>
    <label class="list-row"><span>Haptics</span><input type="checkbox" class="switch" data-haptics ${state.settings.haptics ? 'checked' : ''}/></label>
  </section>

  <section class="card list">
    <div class="list-head">Data</div>
    <button class="list-row" data-export><span>Back up data</span><span class="muted">Export JSON ›</span></button>
    <button class="list-row" data-import><span>Restore backup</span><span class="muted">›</span></button>
    <button class="list-row danger" data-reset><span>Reset everything</span><span>›</span></button>
  </section>

  <section class="card list">
    <div class="list-head">About</div>
    <button class="list-row" data-guide><span>How to play</span><span class="muted">›</span></button>
    <button class="list-row" data-about><span>How the AI works</span><span class="muted">›</span></button>
    <div class="list-row static"><span>Version</span><span class="muted">${APP_VERSION} · offline AI</span></div>
  </section>
  <p class="muted tiny center">All data and photos stay on this phone. No account, no subscription, no API keys.</p>
  <div class="spacer"></div>`;

  root.querySelectorAll('[data-edit]').forEach((b) => (b.onclick = () => EDITORS[b.dataset.edit](app)));
  root.querySelector('[data-units]').onchange = (e) => app.update((s) => (s.settings.units = e.target.value));
  root.querySelector('[data-reminders]').onchange = async (e) => {
    const on = e.target.checked;
    if (on && Capacitor.isNativePlatform()) {
      const perm = await LocalNotifications.requestPermissions().catch(() => ({ display: 'denied' }));
      if (perm.display !== 'granted') toast('Allow notifications in Android settings to get reminders', { type: 'error' });
    }
    app.update((s) => (s.settings.reminders = on));
  };
  root.querySelector('[data-haptics]').onchange = (e) => {
    setHaptics(e.target.checked);
    app.update((s) => (s.settings.haptics = e.target.checked));
  };
  root.querySelector('[data-reset-cal]')?.addEventListener('click', () => app.update((s) => (s.profile.calibration = 1)));
  root.querySelector('[data-export]').onclick = () => exportData(app);
  root.querySelector('[data-import]').onclick = () => importData(app);
  root.querySelector('[data-reset]').onclick = async () => {
    if (!(await confirmDialog({ title: 'Reset everything?', message: 'This deletes your profile, food log, scans, XP and rank from this phone. Back up first if you might want it.', confirm: 'Delete all', danger: true }))) return;
    if (!(await confirmDialog({ title: 'Are you really sure?', message: 'There is no undo.', confirm: 'Yes, wipe it', danger: true }))) return;
    app.state = emptyState();
    saveState(app.state);
    await flush();
    app.tab = 'home';
    document.querySelector('#app').innerHTML = '';
    app.refresh();
    app.render();
    app.scheduleReminders(); // cancels pending streak/challenge notifications
  };
  root.querySelector('[data-about]').onclick = () => aboutSheet();
  root.querySelector('[data-guide]').onclick = () => showGuide();
}

const EDITORS = {
  profile(app) {
    const p = app.state.profile;
    const imp = app.state.settings.units !== 'metric';
    const { ft, inch } = cmToFtIn(p.heightCm);
    sheet((el, close) => {
      el.innerHTML = `
        <h2 class="sheet-title">Body stats</h2>
        <label class="label">Name</label><input class="input" data-name maxlength="24" value="${esc(p.name)}"/>
        <label class="label">Sex</label>
        <select class="select block" data-sex><option value="male" ${p.sex === 'male' ? 'selected' : ''}>Male</option><option value="female" ${p.sex === 'female' ? 'selected' : ''}>Female</option></select>
        <label class="label">Age</label><input class="input" data-age type="number" inputmode="numeric" value="${p.age}"/>
        <label class="label">Height</label>
        ${imp ? `<div class="row gap"><div class="input-unit"><input class="input" data-ft type="number" value="${ft}"/><span>ft</span></div><div class="input-unit"><input class="input" data-in type="number" value="${inch}"/><span>in</span></div></div>` : `<div class="input-unit"><input class="input" data-cm type="number" value="${p.heightCm}"/><span>cm</span></div>`}
        <label class="label">Weight</label>
        <div class="input-unit"><input class="input" data-w type="number" inputmode="decimal" value="${imp ? Math.round(kgToLb(p.weightKg) * 10) / 10 : p.weightKg}"/><span>${imp ? 'lb' : 'kg'}</span></div>
        <div class="onb-error" data-err></div>
        <button class="btn btn-primary btn-block btn-lg" data-save>Save</button>`;
      el.querySelector('[data-save]').onclick = () => {
        const v = (s) => Number(el.querySelector(s)?.value) || 0;
        // Only convert values the user actually changed, so unit rounding never drifts stored height/weight.
        const hChanged = imp ? v('[data-ft]') !== ft || v('[data-in]') !== inch : v('[data-cm]') !== p.heightCm;
        const heightCm = hChanged ? (imp ? inToCm(v('[data-ft]') * 12 + v('[data-in]')) : v('[data-cm]')) : p.heightCm;
        const wShown = imp ? Math.round(kgToLb(p.weightKg) * 10) / 10 : p.weightKg;
        const weightKg = v('[data-w]') !== wShown ? (imp ? lbToKg(v('[data-w]')) : v('[data-w]')) : p.weightKg;
        const age = v('[data-age]');
        const name = el.querySelector('[data-name]').value.trim();
        const err = !name ? 'Enter a name.' : age < 13 || age > 100 ? 'Age must be 13–100.' : heightCm < 120 || heightCm > 230 ? 'Check your height.' : weightKg < 30 || weightKg > 300 ? 'Check your weight.' : '';
        if (err) {
          el.querySelector('[data-err]').textContent = err;
          return;
        }
        app.update((s) => {
          const changedWeight = Math.abs(s.profile.weightKg - weightKg) > 0.05;
          Object.assign(s.profile, { name, sex: el.querySelector('[data-sex]').value, age, heightCm: Math.round(heightCm * 10) / 10, weightKg: Math.round(weightKg * 10) / 10 });
          if (changedWeight) s.weights = [...(s.weights || []).filter((x) => x.date !== app.today), { date: app.today, kg: s.profile.weightKg }];
        });
        close();
        toast('Profile updated', { icon: '✅' });
      };
    });
  },
  goal(app) {
    const p = app.state.profile;
    let goal = p.goal;
    let activity = p.activity;
    sheet((el, close) => {
      const draw = () => {
        el.innerHTML = `
          <h2 class="sheet-title">Goal & activity</h2>
          <div class="choices">${Object.entries(GOALS).map(([k, g]) => `<button class="choice ${goal === k ? 'selected' : ''}" data-goal="${k}"><span class="choice-icon">${g.emoji}</span><span class="choice-text"><b>${g.label}</b><small>${g.hint}</small></span></button>`).join('')}</div>
          <label class="label">Activity</label>
          <div class="choices">${ACTIVITY_LEVELS.map((a) => `<button class="choice sm ${activity === a.value ? 'selected' : ''}" data-act="${a.value}"><span class="choice-text"><b>${a.label}</b><small>${a.hint}</small></span></button>`).join('')}</div>
          <button class="btn btn-primary btn-block btn-lg mt" data-save>Save & recalculate targets</button>`;
        el.querySelectorAll('[data-goal]').forEach((b) => (b.onclick = () => ((goal = b.dataset.goal), draw())));
        el.querySelectorAll('[data-act]').forEach((b) => (b.onclick = () => ((activity = Number(b.dataset.act)), draw())));
        el.querySelector('[data-save]').onclick = () => {
          app.update((s) => Object.assign(s.profile, { goal, activity, customGoals: false }));
          close();
          toast(`Targets: ${app.state.profile.calorieGoal} kcal · ${app.state.profile.proteinGoal}g protein`, { icon: '🎯' });
        };
      };
      draw();
    });
  },
  targets(app) {
    const p = app.state.profile;
    const auto = targetsFor(p);
    sheet((el, close) => {
      el.innerHTML = `
        <h2 class="sheet-title">Daily targets</h2>
        <p class="muted small">Recommended for you: ${fmt(auto.calorieGoal)} kcal · ${auto.proteinGoal}g protein.</p>
        <label class="label">Calories</label><input class="input input-xl" data-k type="number" value="${p.calorieGoal}"/>
        <div class="grid3">
          <div><label class="label">Protein g</label><input class="input" data-p type="number" value="${p.proteinGoal}"/></div>
          <div><label class="label">Carbs g</label><input class="input" data-c type="number" value="${p.carbsGoal}"/></div>
          <div><label class="label">Fat g</label><input class="input" data-f type="number" value="${p.fatGoal}"/></div>
        </div>
        <div class="onb-error" data-err></div>
        <div class="row gap mt"><button class="btn btn-ghost" data-auto>Use recommended</button><button class="btn btn-primary grow" data-save>Save</button></div>`;
      el.querySelector('[data-auto]').onclick = () => {
        app.update((s) => (s.profile.customGoals = false));
        close();
      };
      el.querySelector('[data-save]').onclick = () => {
        const v = (s) => Math.round(Number(el.querySelector(s).value) || 0);
        const k = v('[data-k]');
        if (k < 1000 || k > 6000) {
          el.querySelector('[data-err]').textContent = 'Calories should be between 1,000 and 6,000.';
          return;
        }
        app.update((s) => Object.assign(s.profile, { customGoals: true, calorieGoal: k, proteinGoal: v('[data-p]'), carbsGoal: v('[data-c]'), fatGoal: v('[data-f]') }));
        close();
      };
    });
  },
};

async function exportData(app) {
  const json = exportJSON(app.state);
  const name = `grindfit-backup-${app.today}.json`;
  try {
    if (Capacitor.isNativePlatform()) {
      const res = await Filesystem.writeFile({ path: name, data: json, directory: Directory.Cache, encoding: Encoding.UTF8 });
      await Share.share({ title: 'GrindFit backup', url: res.uri, dialogTitle: 'Save your backup' });
    } else {
      const a = document.createElement('a');
      a.href = URL.createObjectURL(new Blob([json], { type: 'application/json' }));
      a.download = name;
      a.click();
    }
  } catch (e) {
    if (!String(e?.message || e).toLowerCase().includes('cancel')) toast(`Export failed: ${e.message || e}`, { type: 'error' });
  }
}

function importData(app) {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'application/json,.json';
  input.onchange = async () => {
    const file = input.files?.[0];
    if (!file) return;
    try {
      const next = importJSON(await file.text());
      if (!(await confirmDialog({ title: 'Restore this backup?', message: `It has ${next.meals.length} meals and ${next.scans.length} scans. Your current data will be replaced.`, confirm: 'Restore' }))) return;
      app.update((s) => {
        for (const k of Object.keys(s)) delete s[k];
        Object.assign(s, next);
      });
      toast('Backup restored', { icon: '✅' });
    } catch (e) {
      toast(e.message || 'Could not read that file', { type: 'error' });
    }
  };
  input.click();
}

function aboutSheet() {
  sheet(
    (el) => {
      el.innerHTML = `
      <h2 class="sheet-title">How GrindFit works</h2>
      <div class="about">
        <h4>📸 Food recognition</h4>
        <p>A Google AIY food classifier (2,000+ dishes) runs on your phone. Matches are paired with a built-in nutrition database of common foods (USDA-style values). Unknown dishes get a rough estimate based on dish type, marked “≈”. Barcodes and the online search use the free <b>Open Food Facts</b> database.</p>
        <h4>🧬 Body-fat scan</h4>
        <p>MediaPipe pose detection with body segmentation outlines your body and finds your joints. Using your height as a ruler, GrindFit measures your waist width (and depth, from a side photo), estimates waist circumference, and applies the <b>Relative Fat Mass (RFM)</b> formula from Woolcott & Bergman (2018), which was validated against DEXA scans in about 3,500 adults. Tape scans use RFM, averaged with the <b>U.S. Navy</b> formula when you add your neck. Doing a tape scan on the same day as a photo scan calibrates future photo scans to your body.</p>
        <p>Expect roughly ±3–5% error. Lighting, clothing, posture and camera angle all matter, so keep your setup consistent and watch the trend.</p>
        <h4>🎯 Targets</h4>
        <p>Calories use the Mifflin-St Jeor equation × your activity level, then −20% for a cut or +10% for a bulk. Protein is set to 1.8–2.2 g per kg of body weight.</p>
        <h4>⚔️ XP, ranks & leagues</h4>
        <p>XP comes only from things you log, so it always matches your history. Ranks go from Iron to Legend, with 3 divisions each. Weekly leagues put you against simulated rivals paced to your recent weeks: the top 3 move up and the bottom 3 move down.</p>
        <h4>⚠️ Disclaimer</h4>
        <p>GrindFit is not a medical device and doesn’t give medical advice. If you have a history of disordered eating, or any health condition, talk to a professional before changing your diet.</p>
      </div>`;
    },
    { full: true },
  );
}
