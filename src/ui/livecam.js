// Full-screen live camera with pose guidance: checks you're fully in frame, then auto-captures
// after a countdown so you can prop your phone up and step back.

import { esc, haptic } from './dom.js';
import { loadVideoPoseModel, detectBodyVideo } from '../ml/vision.js';

const NEED = { nose: 0, lShoulder: 11, rShoulder: 12, lHip: 23, rHip: 24, lAnkle: 27, rAnkle: 28 };

function frameCheck(lm, view) {
  if (!lm) return { ok: false, msg: 'Step into the frame' };
  const v = (i) => lm[i] && lm[i].visibility > 0.5;
  const ys = lm.filter((p) => p.visibility > 0.5).map((p) => p.y);
  const top = Math.min(...ys);
  const ankles = [NEED.lAnkle, NEED.rAnkle].filter(v);
  if (!v(NEED.nose) && view === 'front') return { ok: false, msg: 'Face the camera' };
  if (!ankles.length) return { ok: false, msg: 'Step back — feet not visible' };
  const bottom = Math.max(...ankles.map((i) => lm[i].y));
  if (top < 0.04) return { ok: false, msg: 'Step back — head too close to the top' };
  if (bottom > 0.97) return { ok: false, msg: 'Step back — feet at the edge' };
  if (bottom - top < 0.5) return { ok: false, msg: 'Come closer' };
  if (view === 'front') {
    const sw = Math.abs(lm[NEED.lShoulder].x - lm[NEED.rShoulder].x);
    if (sw < 0.06) return { ok: false, msg: 'Turn to face the camera' };
    // Arms away from the torso: wrists should be outside the hips.
    const hipL = Math.max(lm[NEED.lHip].x, lm[NEED.rHip].x);
    const hipR = Math.min(lm[NEED.lHip].x, lm[NEED.rHip].x);
    const wrists = [lm[15], lm[16]].filter((p) => p && p.visibility > 0.5);
    const tucked = wrists.some((w) => w.x < hipL + 0.03 && w.x > hipR - 0.03 && w.y > lm[NEED.lShoulder].y);
    if (tucked) return { ok: false, msg: 'Hold your arms out (A-pose)' };
  } else {
    const sw = Math.abs(lm[NEED.lShoulder].x - lm[NEED.rShoulder].x);
    if (sw > 0.12) return { ok: false, msg: 'Turn sideways' };
  }
  return { ok: true, msg: 'Perfect — hold still' };
}

// Resolves with a canvas of the captured frame, or null if closed.
export function liveCapture({ view = 'front', facing = 'environment' } = {}) {
  return new Promise((resolve) => {
    const el = document.createElement('div');
    el.className = 'livecam';
    el.innerHTML = `
      <video playsinline muted autoplay></video>
      <svg class="guide" viewBox="0 0 100 200" preserveAspectRatio="xMidYMid meet">
        ${view === 'front'
          ? '<path d="M50 14a9 9 0 1 1 0 18a9 9 0 1 1 0-18M37 38h26l14 40-6 3-10-26v45l4 66h-9l-6-58-6 58h-9l4-66V55L29 81l-6-3z"/>'
          : '<path d="M50 14a9 9 0 1 1 0 18a9 9 0 1 1 0-18M44 38h12l4 30 2 32-3 4 2 66h-9l-3-60-3 60h-8l2-66-2-38z"/>'}
      </svg>
      <div class="lc-top">
        <button class="lc-btn" data-close aria-label="Close">✕</button>
        <div class="lc-title">${view === 'front' ? 'Front photo' : 'Side photo'}</div>
        <button class="lc-btn" data-flip aria-label="Flip camera">⟲</button>
      </div>
      <div class="lc-status" data-status>Starting camera…</div>
      <div class="lc-count" data-count></div>
      <div class="lc-bottom">
        <label class="lc-auto"><input type="checkbox" data-auto checked/> Auto-capture</label>
        <button class="lc-shutter" data-shoot aria-label="Take photo"></button>
        <div class="lc-hint">${view === 'front' ? 'Arms out · fitted clothes' : 'Stand side-on · arms forward'}</div>
      </div>`;
    document.body.appendChild(el);
    const video = el.querySelector('video');
    const status = el.querySelector('[data-status]');
    const countEl = el.querySelector('[data-count]');
    let stream = null;
    let model = null;
    let raf = 0;
    let goodSince = 0;
    let counting = 0;
    let closed = false;
    let lastDetect = 0;

    const stop = () => {
      closed = true;
      cancelAnimationFrame(raf);
      clearInterval(counting);
      stream?.getTracks().forEach((t) => t.stop());
      el.remove();
    };
    const capture = () => {
      const c = document.createElement('canvas');
      c.width = video.videoWidth;
      c.height = video.videoHeight;
      const ctx = c.getContext('2d');
      if (facing === 'user') {
        ctx.translate(c.width, 0);
        ctx.scale(-1, 1);
      }
      ctx.drawImage(video, 0, 0);
      haptic('heavy');
      el.classList.add('flash');
      setTimeout(() => {
        stop();
        resolve(c);
      }, 180);
    };
    const startCountdown = () => {
      if (counting) return;
      let n = 5;
      countEl.textContent = n;
      haptic('light');
      counting = setInterval(() => {
        n -= 1;
        if (n <= 0) {
          clearInterval(counting);
          counting = 0;
          countEl.textContent = '';
          capture();
        } else {
          countEl.textContent = n;
          haptic('light');
        }
      }, 1000);
    };
    const cancelCountdown = () => {
      if (!counting) return;
      clearInterval(counting);
      counting = 0;
      countEl.textContent = '';
    };

    const loop = () => {
      if (closed) return;
      raf = requestAnimationFrame(loop);
      if (!model || video.readyState < 2) return;
      const now = performance.now();
      if (now - lastDetect < 120) return;
      lastDetect = now;
      let lm = null;
      try {
        lm = detectBodyVideo(model, video);
      } catch (e) {
        console.warn(e);
      }
      const chk = frameCheck(lm, view);
      status.textContent = chk.msg;
      status.classList.toggle('good', chk.ok);
      el.classList.toggle('aligned', chk.ok);
      const auto = el.querySelector('[data-auto]').checked;
      if (chk.ok) {
        goodSince ||= now;
        if (auto && now - goodSince > 700) startCountdown();
      } else {
        goodSince = 0;
        if (counting && auto) cancelCountdown();
      }
    };

    const start = async () => {
      stream?.getTracks().forEach((t) => t.stop());
      try {
        stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: facing, width: { ideal: 1280 }, height: { ideal: 1920 } }, audio: false });
      } catch (e) {
        status.innerHTML = `Camera unavailable: ${esc(e.message || e.name)}<br/><small>Allow camera access in Settings, or use “Upload photo”.</small>`;
        return;
      }
      video.srcObject = stream;
      video.classList.toggle('mirror', facing === 'user');
      await video.play().catch(() => {});
      status.textContent = 'Loading pose AI…';
      try {
        model ||= await loadVideoPoseModel();
        status.textContent = 'Step back until your whole body fits';
      } catch (e) {
        status.textContent = 'Pose guide unavailable — use the shutter button';
      }
      cancelAnimationFrame(raf);
      loop();
    };

    el.querySelector('[data-close]').onclick = () => {
      stop();
      resolve(null);
    };
    el.querySelector('[data-flip]').onclick = () => {
      facing = facing === 'user' ? 'environment' : 'user';
      cancelCountdown();
      start();
    };
    el.querySelector('[data-shoot]').onclick = () => {
      if (counting) return;
      if (el.querySelector('[data-auto]').checked) startCountdown();
      else capture();
    };
    el.querySelector('[data-auto]').onchange = () => cancelCountdown();
    el._close = () => {
      stop();
      resolve(null);
    };
    start();
  });
}

export function closeLiveCam() {
  const el = document.querySelector('.livecam');
  if (el && el._close) {
    el._close();
    return true;
  }
  return false;
}
