// Body scan tab: guided photo scan (front + optional side), tape-measure scan, history.

import { esc, fmt, sheet, toast, haptic, confirmDialog } from './dom.js';
import { lineChart } from './charts.js';
import { pickImage, toCanvas, thumbnail } from '../ml/media.js';
import { analyzeBodyPhoto } from '../ml/bodyscan.js';
import { liveCapture } from './livecam.js';
import { estimateFromPhotos, estimateFromTape, categoryFor, CATEGORIES, whtrLabel, WARNING_TEXT, weightAtBodyFat, leanMassKg, ScanError, round1 } from '../lib/bodyfat.js';
import { shortDay } from '../lib/dates.js';
import { kgToLb, lbToKg, cmToIn, inToCm } from '../lib/nutrition.js';
import { uid } from '../store.js';
import { storeThumb, deleteThumb } from '../thumbs.js';

const imperial = (app) => app.state.settings.units !== 'metric';
const lenUnit = (app) => (imperial(app) ? 'in' : 'cm');
const showLen = (app, cm) => (imperial(app) ? `${fmt(cmToIn(cm), 1)} in` : `${fmt(cm, 1)} cm`);
const showWt = (app, kg) => (imperial(app) ? `${fmt(kgToLb(kg), 1)} lb` : `${fmt(kg, 1)} kg`);

export function renderScan(root, app) {
  const { state } = app;
  const p = state.profile;
  const scans = [...state.scans].sort((a, b) => a.time.localeCompare(b.time));
  const last = scans[scans.length - 1];
  const first = scans[0];
  // Your best result on your first scan day is the baseline (same-day rescans are calibration, not progress).
  const baseline = first ? Math.min(...scans.filter((x) => x.date === first.date).map((x) => x.bodyFat)) : 0;
  const adult = p.age >= 18;
  const cat = last ? categoryFor(p.sex, last.bodyFat) : null;

  root.innerHTML = `
  <header class="page-head"><h1 class="h1">Body scan</h1></header>
  ${
    last
      ? `<section class="card bf-hero" style="--cat:${cat.color}">
          <div class="bf-label muted small">Latest · ${esc(shortDay(last.date))}</div>
          <div class="bf-num">${fmt(last.bodyFat, 1)}<span>%</span></div>
          <div class="bf-cat" style="color:${cat.color}">${esc(cat.label)}</div>
          ${scaleBar(p.sex, last.bodyFat)}
          ${last.date !== first.date ? `<div class="bf-delta ${last.bodyFat <= baseline ? 'good' : 'bad'}">${last.bodyFat <= baseline ? '▼' : '▲'} ${fmt(Math.abs(last.bodyFat - baseline), 1)}% since ${esc(shortDay(first.date))}</div>` : ''}
        </section>`
      : `<section class="card bf-empty">
          <div class="bf-empty-art">🧬</div>
          <h2>Get your baseline</h2>
          <p class="muted small">Your first scan sets the bar. Every new low after that earns big XP.</p>
        </section>`
  }
  ${
    adult
      ? `<div class="scan-options">
          <button class="scan-opt primary" data-photo>
            <span class="so-icon">📷</span>
            <span class="so-text"><b>AI photo scan</b><small>Full-body photo · ~30 sec</small></span><span class="so-arrow">›</span>
          </button>
          <button class="scan-opt" data-tape>
            <span class="so-icon">📏</span>
            <span class="so-text"><b>Tape measure scan</b><small>Most accurate · waist & neck</small></span><span class="so-arrow">›</span>
          </button>
        </div>`
      : `<div class="banner">Body-fat scans are for users 18+. Keep grinding with food tracking and challenges — your body is still developing, so focus on eating well and training hard.</div>`
  }
  ${
    scans.length >= 2
      ? `<section class="card"><div class="card-head"><h3>Body fat trend</h3><span class="muted small">${scans.length} scans</span></div>
          ${lineChart(scans.slice(-20).map((s) => ({ x: shortDay(s.date), y: s.bodyFat, lo: s.low, hi: s.high })), { unit: '%', color: 'var(--accent)' })}</section>`
      : ''
  }
  ${
    scans.length
      ? `<section class="card"><div class="card-head"><h3>History</h3></div>
          ${[...scans]
            .reverse()
            .slice(0, 30)
            .map(
              (s) => `<button class="scan-row" data-scan="${esc(s.id)}">
                ${s.thumb ? `<img src="${esc(s.thumb)}" alt=""/>` : '<div class="ph">📏</div>'}
                <div class="grow left"><b>${fmt(s.bodyFat, 1)}%</b> <span class="muted tiny">${fmt(s.low, 1)}–${fmt(s.high, 1)}%</span><div class="muted tiny">${esc(shortDay(s.date))} · ${methodLabel(s.method)}</div></div>
                <span class="muted">›</span></button>`,
            )
            .join('')}</section>`
      : ''
  }
  <section class="card how">
    <h3>How it works</h3>
    <p class="muted small">On-device AI outlines your body and finds your shoulders, hips and feet. Your real height is the ruler: it measures your waist, estimates its circumference, then applies the <b>Relative Fat Mass</b> formula (validated against DEXA scans). A side photo or a tape measure makes it more accurate.</p>
    <p class="muted tiny">Estimates are typically within ±3–5%. Track the trend, not a single number. Not medical advice.</p>
  </section>
  <div class="spacer"></div>`;

  root.querySelector('[data-photo]')?.addEventListener('click', () => photoScanFlow(app));
  root.querySelector('[data-tape]')?.addEventListener('click', () => tapeFlow(app));
  root.querySelectorAll('[data-scan]').forEach((b) => (b.onclick = () => showScan(app, b.dataset.scan)));
}

function methodLabel(m) {
  return { photo: 'Photo (front)', photo2: 'Photo (front + side)', tape: 'Tape (RFM)', tape_navy: 'Tape (RFM + Navy)' }[m] || 'Scan';
}

function scaleBar(sex, bf) {
  const cats = CATEGORIES[sex === 'female' ? 'female' : 'male'];
  const min = sex === 'female' ? 10 : 3;
  const max = sex === 'female' ? 45 : 35;
  let prev = min;
  const segs = cats.map((c) => {
    const end = Math.min(max, c.max === Infinity ? max : c.max + 0.1);
    const w = ((end - prev) / (max - min)) * 100;
    prev = end;
    return `<div style="width:${w}%;background:${c.color}"></div>`;
  });
  const pos = Math.max(0, Math.min(100, ((bf - min) / (max - min)) * 100));
  return `<div class="bf-scale"><div class="bf-track">${segs.join('')}</div><div class="bf-marker" style="left:${pos}%"></div></div>`;
}

// ---------- photo scan ----------

async function photoScanFlow(app) {
  const p = app.state.profile;
  const res = await sheet((el, close) => {
    el.innerHTML = `
      <h2 class="sheet-title">AI photo scan</h2>
      <div class="tips">
        <div class="tip"><span>📐</span><div><b>Whole body in frame</b><small>Head to feet, phone at waist height, 2–3 m away</small></div></div>
        <div class="tip"><span>🙆</span><div><b>A-pose</b><small>Arms out from your sides, feet hip-width</small></div></div>
        <div class="tip"><span>👕</span><div><b>Fitted clothes or shirtless</b><small>Loose clothes make you read higher</small></div></div>
        <div class="tip"><span>💡</span><div><b>Plain background, good light</b><small>Same spot & time each scan for a clean trend</small></div></div>
      </div>
      <div class="ruler-note">Using your height <b>${showLen(app, p.heightCm)}</b> as the ruler. <button class="link-btn" data-edit-h>Wrong?</button></div>
      <button class="btn btn-primary btn-lg btn-block" data-live>Open camera (auto-timer)</button>
      <button class="btn btn-ghost btn-block" data-upload>Upload a photo</button>
      <p class="muted tiny center mt">Photos never leave your phone.</p>`;
    el.querySelector('[data-live]').onclick = () => close('live');
    el.querySelector('[data-upload]').onclick = () => close('upload');
    el.querySelector('[data-edit-h]').onclick = () => close('edit');
  });
  if (!res) return;
  if (res === 'edit') {
    app.go('me');
    toast('Update your height in Profile', { icon: '📏' });
    return;
  }
  const front = await getPhoto(res, 'front');
  if (!front) return;
  const frontResult = await runAnalysis(front, 'front');
  if (!frontResult) return;

  // Optional side photo for depth.
  const wantSide = await sheet((el, close) => {
    el.innerHTML = `
      <div class="center">
        <img class="overlay-img sm" src="${esc(frontResult.overlay)}" alt=""/>
        <h2 class="sheet-title">Front scan locked in ✅</h2>
        <p class="muted small">Add a <b>side photo</b> so the AI can measure your waist depth too. It noticeably improves accuracy.</p>
      </div>
      <button class="btn btn-primary btn-lg btn-block" data-side>Add side photo</button>
      <button class="btn btn-ghost btn-block" data-skip>Skip, show my result</button>`;
    el.querySelector('[data-side]').onclick = () => close(true);
    el.querySelector('[data-skip]').onclick = () => close(false);
  }, { dismissible: false });
  let sideResult = null;
  if (wantSide) {
    const side = await getPhoto(res, 'side');
    if (side) sideResult = await runAnalysis(side, 'side', true);
  }
  const est = estimateFromPhotos({ sex: p.sex, heightCm: p.heightCm, front: frontResult.measurement, side: sideResult?.measurement, calibration: p.calibration || 1 });
  await saveScan(app, est, { thumb: frontResult.thumb, overlay: frontResult.overlay, warnings: frontResult.measurement.warnings });
}

async function getPhoto(mode, view) {
  try {
    if (mode === 'live') {
      const c = await liveCapture({ view });
      return c;
    }
    const img = await pickImage('gallery');
    return toCanvas(img, 1280);
  } catch (e) {
    if (e.message !== 'cancelled') toast(e.message || 'Could not get photo', { type: 'error' });
    return null;
  }
}

async function runAnalysis(source, view, optional = false) {
  const canvas = toCanvas(source, 1280);
  const thumb = thumbnail(canvas, 260);
  let closeLoader;
  sheet(
    (el, close) => {
      closeLoader = close;
      el.innerHTML = `
      <div class="analyzing">
        <div class="scan-frame tall"><img src="${esc(thumb)}" alt=""/><div class="scan-line"></div></div>
        <b>Scanning ${view} view…</b>
        <span class="muted small">Detecting pose & body outline</span>
      </div>`;
    },
    { dismissible: false },
  );
  try {
    const r = await analyzeBodyPhoto(canvas, view);
    closeLoader();
    return { ...r, thumb };
  } catch (e) {
    closeLoader();
    console.error(e);
    const msg = e instanceof ScanError ? e.message : `The scan AI failed to run: ${e.message || e}`;
    await sheet((el, close) => {
      el.innerHTML = `
        <div class="center">
          <div class="empty-icon">⚠️</div>
          <h2 class="sheet-title">Couldn’t measure that photo</h2>
          <p class="muted">${esc(msg)}</p>
        </div>
        <button class="btn btn-primary btn-block" data-ok>${optional ? 'Continue without it' : 'Try again'}</button>`;
      el.querySelector('[data-ok]').onclick = () => close();
    });
    haptic('warning');
    return null;
  }
}

// ---------- tape ----------

function tapeFlow(app) {
  const p = app.state.profile;
  const u = lenUnit(app);
  sheet((el, close) => {
    el.innerHTML = `
      <h2 class="sheet-title">Tape measure scan</h2>
      <p class="muted small">Measure on bare skin, relaxed, after breathing out. Don’t suck in.</p>
      <label class="label">Waist at belly button (${u}) <span class="req">required</span></label>
      <input class="input input-xl" data-waist type="number" inputmode="decimal" placeholder="${u === 'in' ? '34' : '86'}"/>
      <label class="label">Neck, below the Adam’s apple (${u}) <span class="muted tiny">optional, improves accuracy</span></label>
      <input class="input" data-neck type="number" inputmode="decimal" placeholder="${u === 'in' ? '15' : '38'}"/>
      ${p.sex === 'female' ? `<label class="label">Hips, widest point (${u}) <span class="muted tiny">optional</span></label><input class="input" data-hip type="number" inputmode="decimal" placeholder="${u === 'in' ? '38' : '97'}"/>` : ''}
      <div class="onb-error" data-err></div>
      <button class="btn btn-primary btn-block btn-lg" data-go>Calculate</button>`;
    const val = (s) => {
      const v = Number(el.querySelector(s)?.value) || 0;
      return u === 'in' ? inToCm(v) : v;
    };
    el.querySelector('[data-go]').onclick = async () => {
      const waistCm = val('[data-waist]');
      const neckCm = val('[data-neck]') || null;
      const hipCm = val('[data-hip]') || null;
      if (waistCm < 45 || waistCm > 200) {
        el.querySelector('[data-err]').textContent = 'Enter a realistic waist measurement.';
        return;
      }
      if (neckCm && (neckCm < 20 || neckCm > 70)) {
        el.querySelector('[data-err]').textContent = 'That neck measurement looks off.';
        return;
      }
      const est = estimateFromTape({ sex: p.sex, heightCm: p.heightCm, waistCm, neckCm, hipCm });
      close();
      // Use this tape waist to calibrate photo scans done today.
      const todayPhoto = [...app.state.scans].reverse().find((s) => s.date === app.today && s.rawWaistCm);
      await saveScan(app, est, { calibrateFrom: todayPhoto });
    };
    setTimeout(() => el.querySelector('[data-waist]').focus(), 60);
  });
}

// ---------- save + result ----------

async function saveScan(app, est, { thumb = null, overlay = null, warnings = [], calibrateFrom = null } = {}) {
  // Confirm current weight (keeps calorie targets fresh and powers lean-mass stats).
  const weightKg = await askWeight(app);
  const id = uid();
  const scan = {
    id,
    date: app.today,
    time: new Date().toISOString(),
    ...est,
    weightKg,
    thumb: thumb ? await storeThumb(id, thumb) : null,
    warnings,
  };
  const prevBest = app.state.scans.length ? Math.min(...app.state.scans.map((s) => s.bodyFat)) : null;
  app.update((s) => {
    s.scans.push(scan);
    if (weightKg) {
      s.profile.weightKg = weightKg;
      s.weights = [...(s.weights || []).filter((w) => w.date !== app.today), { date: app.today, kg: weightKg }];
    }
    if (calibrateFrom && calibrateFrom.rawWaistCm) {
      s.profile.calibration = round1((est.waistCm / calibrateFrom.rawWaistCm) * 100) / 100;
    }
  });
  if (calibrateFrom) toast('Photo scans calibrated to your tape measurement', { icon: '🎯' });
  showResult(app, scan, { overlay, prevBest, fresh: true });
}

function askWeight(app) {
  const p = app.state.profile;
  const imp = imperial(app);
  return sheet(
    (el, close) => {
      el.innerHTML = `
      <h2 class="sheet-title">Current weight?</h2>
      <p class="muted small">Weigh in the morning for the cleanest trend.</p>
      <div class="input-unit"><input class="input input-xl" data-w type="number" inputmode="decimal" value="${imp ? round1(kgToLb(p.weightKg)) : round1(p.weightKg)}"/><span>${imp ? 'lb' : 'kg'}</span></div>
      <button class="btn btn-primary btn-block btn-lg mt" data-ok>Show my result</button>`;
      el.querySelector('[data-ok]').onclick = () => {
        const v = Number(el.querySelector('[data-w]').value);
        const kg = imp ? lbToKg(v) : v;
        close(kg >= 30 && kg <= 300 ? round1(kg) : p.weightKg);
      };
    },
    { dismissible: false },
  );
}

function showScan(app, id) {
  const scan = app.state.scans.find((s) => s.id === id);
  if (scan) showResult(app, scan, {});
}

function showResult(app, scan, { overlay, prevBest, fresh }) {
  const p = app.state.profile;
  const cat = categoryFor(p.sex, scan.bodyFat);
  const cats = CATEGORIES[p.sex === 'female' ? 'female' : 'male'];
  const idx = cats.indexOf(cat);
  const nextCat = idx > 1 ? cats[idx - 1] : null;
  const wt = scan.weightKg || p.weightKg;
  const target = nextCat ? nextCat.max - 0.5 : null;
  const loseKg = target ? wt - weightAtBodyFat(wt, scan.bodyFat, target) : 0;
  const lean = leanMassKg(wt, scan.bodyFat);
  const wl = scan.whtr ? whtrLabel(scan.whtr) : null;
  const newLow = fresh && prevBest !== null && scan.bodyFat <= prevBest - 0.5;
  if (fresh) haptic('success');
  sheet(
    (el, close) => {
      el.innerHTML = `
      <div class="result">
        ${overlay ? `<img class="overlay-img" src="${esc(overlay)}" alt="Scan overlay"/>` : ''}
        ${newLow ? '<div class="new-low">🏆 NEW PERSONAL BEST</div>' : ''}
        <div class="bf-num big">${fmt(scan.bodyFat, 1)}<span>%</span></div>
        <div class="muted small">Likely range ${fmt(scan.low, 1)}–${fmt(scan.high, 1)}% · ${methodLabel(scan.method)}</div>
        <div class="bf-cat" style="color:${cat.color}">${esc(cat.label)}</div>
        ${scaleBar(p.sex, scan.bodyFat)}
        <div class="stat-grid">
          ${scan.waistCm ? `<div class="stat"><b>${showLen(app, scan.waistCm)}</b><span>Waist ${scan.method.startsWith('photo') ? '(est.)' : ''}</span></div>` : ''}
          ${wl ? `<div class="stat"><b style="color:${wl.color}">${scan.whtr.toFixed(2)}</b><span>Waist/height · ${esc(wl.label)}</span></div>` : ''}
          <div class="stat"><b>${showWt(app, lean)}</b><span>Lean mass</span></div>
          <div class="stat"><b>${showWt(app, wt * (scan.bodyFat / 100))}</b><span>Fat mass</span></div>
        </div>
        ${nextCat && loseKg > 0.2 ? `<div class="card goal-card">🎯 Lose about <b>${showWt(app, loseKg)}</b> of fat (keeping your muscle) to reach <b style="color:${nextCat.color}">${esc(nextCat.label)}</b> (${target}%).</div>` : ''}
        ${(scan.warnings || []).map((w) => `<div class="banner">${esc(WARNING_TEXT[w] || w)}</div>`).join('')}
        ${scan.method === 'photo' ? '<p class="muted tiny">Tip: add a side photo next time, or do a tape scan on the same day to calibrate photo scans to you.</p>' : ''}
        ${scan.navy ? `<p class="muted tiny">RFM ${fmt(scan.rfm, 1)}% · Navy ${fmt(scan.navy, 1)}% (averaged)</p>` : ''}
        <div class="row gap mt">
          ${fresh ? '' : '<button class="btn btn-danger" data-del>Delete</button>'}
          <button class="btn btn-primary grow" data-ok>${fresh ? 'Claim XP 💪' : 'Close'}</button>
        </div>
      </div>`;
      el.querySelector('[data-ok]').onclick = () => close();
      el.querySelector('[data-del]')?.addEventListener('click', async () => {
        if (!(await confirmDialog({ title: 'Delete scan?', message: 'This removes it from your history and XP.', confirm: 'Delete', danger: true }))) return;
        app.update((s) => (s.scans = s.scans.filter((x) => x.id !== scan.id)));
        deleteThumb(scan.id, scan.thumb);
        close();
      });
    },
    { full: true },
  );
}
