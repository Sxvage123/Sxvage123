// First-run setup: collects body stats and goal, computes targets, then drops you into the grind.

import { esc, haptic } from './dom.js';
import { ACTIVITY_LEVELS, GOALS, computeTargets, lbToKg, inToCm, kgToLb, cmToFtIn } from '../lib/nutrition.js';
import { targetsFor } from '../app.js';

const STEPS = ['welcome', 'name', 'basics', 'body', 'activity', 'goal', 'summary'];

let draft = null;
let step = 0;

export function renderOnboarding(root, app) {
  if (!draft) {
    draft = { name: '', sex: 'male', age: '', units: 'imperial', heightCm: null, weightKg: null, ft: '', inch: '', lb: '', cm: '', kg: '', activity: 1.55, goal: 'cut' };
  }
  const id = STEPS[step];
  root.innerHTML = `
    <div class="onb">
      ${step > 0 ? `<div class="onb-top"><button class="icon-btn" data-back aria-label="Back">‹</button><div class="onb-progress"><div style="width:${(step / (STEPS.length - 1)) * 100}%"></div></div></div>` : ''}
      <div class="onb-body">${BODY[id]()}</div>
      <div class="onb-actions">
        <div class="onb-error" id="onb-error"></div>
        <button class="btn btn-primary btn-block btn-lg" data-next>${id === 'welcome' ? 'Start the grind' : id === 'summary' ? 'Let’s go 🔥' : 'Continue'}</button>
      </div>
    </div>`;
  const q = (s) => root.querySelector(s);
  q('[data-back]')?.addEventListener('click', () => {
    step = Math.max(0, step - 1);
    renderOnboarding(root, app);
  });
  root.querySelectorAll('[data-choice]').forEach((b) =>
    b.addEventListener('click', () => {
      const [key, val] = b.dataset.choice.split(':');
      draft[key] = key === 'activity' ? Number(val) : val;
      haptic('light');
      if (key === 'units') convertUnits();
      renderOnboarding(root, app);
    }),
  );
  root.querySelectorAll('input[data-k]').forEach((inp) =>
    inp.addEventListener('input', () => {
      draft[inp.dataset.k] = inp.value;
    }),
  );
  q('[data-next]').addEventListener('click', () => {
    const err = validate(id);
    if (err) {
      q('#onb-error').textContent = err;
      haptic('warning');
      return;
    }
    if (id === 'summary') {
      const profile = buildProfile();
      app.update((s) => {
        s.profile = profile;
        s.settings.units = draft.units;
        s.weights.push({ date: app.today, kg: profile.weightKg });
      });
      draft = null;
      step = 0;
      return;
    }
    step += 1;
    renderOnboarding(root, app);
  });
  root.querySelector('input')?.focus({ preventScroll: true });
}

function convertUnits() {
  // Carry values across when the unit toggle flips.
  const h = heightCm();
  const w = weightKg();
  if (draft.units === 'metric') {
    if (h) draft.cm = String(Math.round(h));
    if (w) draft.kg = String(Math.round(w * 10) / 10);
  } else {
    if (h) {
      const { ft, inch } = cmToFtIn(h);
      draft.ft = String(ft);
      draft.inch = String(inch);
    }
    if (w) draft.lb = String(Math.round(kgToLb(w)));
  }
}

function heightCm() {
  if (draft.units === 'metric') return Number(draft.cm) || null;
  const ft = Number(draft.ft) || 0;
  const inch = Number(draft.inch) || 0;
  return ft || inch ? inToCm(ft * 12 + inch) : null;
}

function weightKg() {
  if (draft.units === 'metric') return Number(draft.kg) || null;
  return Number(draft.lb) ? lbToKg(Number(draft.lb)) : null;
}

function validate(id) {
  if (id === 'name' && !draft.name.trim()) return 'What should we call you?';
  if (id === 'basics') {
    const age = Number(draft.age);
    if (!age || age < 13 || age > 100) return 'Enter an age between 13 and 100.';
  }
  if (id === 'body') {
    const h = heightCm();
    const w = weightKg();
    if (!h || h < 120 || h > 230) return 'Enter a height between 4′0″ and 7′6″ (120–230 cm).';
    if (!w || w < 30 || w > 300) return 'Enter a weight between 66 and 660 lb (30–300 kg).';
  }
  return '';
}

function buildProfile() {
  const p = {
    name: draft.name.trim().slice(0, 24),
    sex: draft.sex,
    age: Number(draft.age),
    heightCm: Math.round(heightCm() * 10) / 10,
    weightKg: Math.round(weightKg() * 10) / 10,
    activity: draft.activity,
    goal: draft.goal,
    customGoals: false,
    calibration: 1,
    createdAt: new Date().toISOString(),
  };
  return { ...p, ...targetsFor(p) };
}

const choice = (key, val, title, hint = '', icon = '') =>
  `<button class="choice ${String(draft[key]) === String(val) ? 'selected' : ''}" data-choice="${key}:${val}">
    ${icon ? `<span class="choice-icon">${icon}</span>` : ''}
    <span class="choice-text"><b>${esc(title)}</b>${hint ? `<small>${esc(hint)}</small>` : ''}</span>
  </button>`;

const BODY = {
  welcome: () => `
    <div class="onb-hero">
      <div class="logo-mark"><svg viewBox="0 0 100 100" width="110" height="110"><defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#d4ff3a"/><stop offset="1" stop-color="#5ee6d0"/></linearGradient></defs><path d="M50 6 L86 20 L82 58 Q78 80 50 94 Q22 80 18 58 L14 20 Z" fill="url(#lg)"/><path d="M58 22 L34 54 H50 L42 80 L68 44 H52 Z" fill="#0b0d12"/></svg></div>
      <h1 class="display">GRIND<span class="accent">FIT</span></h1>
      <p class="lead">Track every meal. Scan your body fat. Rank up from <b>Iron</b> to <b>Legend</b>.</p>
      <ul class="feature-list">
        <li><span>📸</span><div><b>Snap your food</b><small>On-device AI recognizes 2,000+ dishes</small></div></li>
        <li><span>🧬</span><div><b>Body-fat scans</b><small>AI body measurement from a photo</small></div></li>
        <li><span>⚔️</span><div><b>Daily challenges & leagues</b><small>Streaks, XP, ranks, badges</small></div></li>
        <li><span>🔒</span><div><b>100% private & free</b><small>Everything runs on your phone. No accounts.</small></div></li>
      </ul>
    </div>`,
  name: () => `
    <h2 class="onb-title">What’s your gamer tag?</h2>
    <p class="muted">This is what shows on the leaderboard.</p>
    <input class="input input-xl" data-k="name" maxlength="24" placeholder="e.g. Sxvage" value="${esc(draft.name)}" autocomplete="off" />`,
  basics: () => `
    <h2 class="onb-title">The basics</h2>
    <p class="muted">Used to calculate your metabolism and body-fat formulas.</p>
    <label class="label">Sex</label>
    <div class="seg">${['male', 'female'].map((v) => `<button class="seg-btn ${draft.sex === v ? 'active' : ''}" data-choice="sex:${v}">${v === 'male' ? '♂ Male' : '♀ Female'}</button>`).join('')}</div>
    <label class="label">Age</label>
    <input class="input input-xl" data-k="age" type="number" inputmode="numeric" placeholder="Years" value="${esc(draft.age)}" />`,
  body: () => `
    <h2 class="onb-title">Height & weight</h2>
    <div class="seg">${['imperial', 'metric'].map((v) => `<button class="seg-btn ${draft.units === v ? 'active' : ''}" data-choice="units:${v}">${v === 'imperial' ? 'ft / lb' : 'cm / kg'}</button>`).join('')}</div>
    <label class="label">Height</label>
    ${
      draft.units === 'imperial'
        ? `<div class="row gap"><div class="input-unit"><input class="input input-xl" data-k="ft" type="number" inputmode="numeric" placeholder="5" value="${esc(draft.ft)}"/><span>ft</span></div>
           <div class="input-unit"><input class="input input-xl" data-k="inch" type="number" inputmode="numeric" placeholder="10" value="${esc(draft.inch)}"/><span>in</span></div></div>`
        : `<div class="input-unit"><input class="input input-xl" data-k="cm" type="number" inputmode="decimal" placeholder="178" value="${esc(draft.cm)}"/><span>cm</span></div>`
    }
    <label class="label">Weight</label>
    ${
      draft.units === 'imperial'
        ? `<div class="input-unit"><input class="input input-xl" data-k="lb" type="number" inputmode="decimal" placeholder="175" value="${esc(draft.lb)}"/><span>lb</span></div>`
        : `<div class="input-unit"><input class="input input-xl" data-k="kg" type="number" inputmode="decimal" placeholder="80" value="${esc(draft.kg)}"/><span>kg</span></div>`
    }
    <p class="muted small mt">Your height is also the ruler for body-fat scans, so be accurate.</p>`,
  activity: () => `
    <h2 class="onb-title">How active are you?</h2>
    <div class="choices">${ACTIVITY_LEVELS.map((a) => choice('activity', a.value, a.label, a.hint)).join('')}</div>`,
  goal: () => `
    <h2 class="onb-title">Pick your mission</h2>
    <div class="choices">${Object.entries(GOALS).map(([k, g]) => choice('goal', k, g.label, g.hint, g.emoji)).join('')}</div>`,
  summary: () => {
    const p = { sex: draft.sex, age: Number(draft.age), heightCm: heightCm(), weightKg: weightKg(), activity: draft.activity, goal: draft.goal };
    const t = computeTargets(p);
    return `
    <h2 class="onb-title">Your daily targets</h2>
    <p class="muted">Based on a maintenance burn of <b>${t.tdee.toLocaleString()} kcal</b>/day. Change these any time in Me → Goals.</p>
    <div class="target-hero"><div class="target-num">${t.calories.toLocaleString()}</div><div class="muted">calories / day</div></div>
    <div class="macro-grid">
      <div class="macro-card p"><b>${t.protein}g</b><span>Protein</span></div>
      <div class="macro-card c"><b>${t.carbs}g</b><span>Carbs</span></div>
      <div class="macro-card f"><b>${t.fat}g</b><span>Fat</span></div>
    </div>
    <div class="card mt">
      <b>How you earn XP</b>
      <ul class="xp-rules">
        <li><span>+10</span> every meal you log</li>
        <li><span>+20</span> log 3 meals in a day</li>
        <li><span>+40</span> hit your protein</li>
        <li><span>+40</span> land your calories on target</li>
        <li><span>+50–240</span> daily challenge (Sunday boss = 2×)</li>
        <li><span>+50</span> body scan, <b>+100</b>/% for new body-fat lows</li>
        <li><span>×1.5</span> max streak multiplier</li>
      </ul>
    </div>`;
  },
};
