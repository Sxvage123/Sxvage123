// Tiny DOM toolkit: escaping, toasts, bottom sheets, modals, confetti, haptics.

import { Haptics, ImpactStyle, NotificationType } from '@capacitor/haptics';
import { Capacitor } from '@capacitor/core';

export const $ = (sel, root = document) => root.querySelector(sel);
export const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

const ESC = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
export const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ESC[c]);

export const fmt = (n, digits = 0) =>
  Number(n || 0).toLocaleString(undefined, { maximumFractionDigits: digits, minimumFractionDigits: digits });

let hapticsOn = true;
export function setHaptics(on) {
  hapticsOn = on;
}
export function haptic(kind = 'light') {
  if (!hapticsOn || !Capacitor.isNativePlatform()) return;
  try {
    if (kind === 'success') Haptics.notification({ type: NotificationType.Success });
    else if (kind === 'warning') Haptics.notification({ type: NotificationType.Warning });
    else if (kind === 'heavy') Haptics.impact({ style: ImpactStyle.Heavy });
    else if (kind === 'medium') Haptics.impact({ style: ImpactStyle.Medium });
    else Haptics.impact({ style: ImpactStyle.Light });
  } catch {
    /* haptics are a nicety */
  }
}

// ---------- toasts ----------

export function toast(message, { type = 'info', icon = '', duration = 2600 } = {}) {
  const host = $('#toasts');
  const el = document.createElement('div');
  el.className = `toast toast-${type}`;
  el.innerHTML = `${icon ? `<span class="toast-icon">${icon}</span>` : ''}<span>${esc(message)}</span>`;
  host.appendChild(el);
  requestAnimationFrame(() => el.classList.add('show'));
  setTimeout(() => {
    el.classList.remove('show');
    setTimeout(() => el.remove(), 300);
  }, duration);
}

export function xpPop(amount) {
  if (!amount) return;
  const el = document.createElement('div');
  el.className = `xp-pop ${amount < 0 ? 'neg' : ''}`;
  el.textContent = `${amount > 0 ? '+' : ''}${amount} XP`;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 1600);
}

// ---------- sheets & modals ----------

const stack = [];

// Opens a bottom sheet. render(el, close) fills it. Returns a promise resolved with close(value).
export function sheet(render, { className = '', dismissible = true, full = false } = {}) {
  return new Promise((resolve) => {
    const backdrop = document.createElement('div');
    backdrop.className = 'sheet-backdrop';
    const el = document.createElement('div');
    el.className = `sheet ${full ? 'sheet-full' : ''} ${className}`;
    el.setAttribute('role', 'dialog');
    el.innerHTML = '<div class="sheet-grip"></div><div class="sheet-body"></div>';
    backdrop.appendChild(el);
    $('#overlays').appendChild(backdrop);
    let closed = false;
    const close = (value) => {
      if (closed) return;
      closed = true;
      stack.splice(stack.indexOf(entry), 1);
      backdrop.classList.remove('open');
      setTimeout(() => backdrop.remove(), 280);
      resolve(value);
    };
    const entry = { close, dismissible };
    stack.push(entry);
    if (dismissible) {
      backdrop.addEventListener('click', (e) => {
        if (e.target === backdrop) close();
      });
      enableSwipeDown(el, () => close());
    }
    render($('.sheet-body', el), close);
    requestAnimationFrame(() => backdrop.classList.add('open'));
  });
}

function enableSwipeDown(el, onClose) {
  const grip = $('.sheet-grip', el);
  let startY = null;
  let dy = 0;
  const start = (e) => {
    startY = e.touches[0].clientY;
    dy = 0;
    el.style.transition = 'none';
  };
  const move = (e) => {
    if (startY === null) return;
    dy = Math.max(0, e.touches[0].clientY - startY);
    el.style.transform = `translateY(${dy}px)`;
  };
  const end = () => {
    el.style.transition = '';
    el.style.transform = '';
    if (dy > 90) onClose();
    startY = null;
  };
  grip.addEventListener('touchstart', start, { passive: true });
  grip.addEventListener('touchmove', move, { passive: true });
  grip.addEventListener('touchend', end);
}

// Closes the top-most overlay (used by the Android back button). Returns true if one was closed.
export function closeTopOverlay() {
  const top = stack[stack.length - 1];
  if (top && top.dismissible) {
    top.close();
    return true;
  }
  return !!top;
}

export function confirmDialog({ title, message, confirm = 'Confirm', danger = false }) {
  return sheet((el, close) => {
    el.innerHTML = `
      <h2 class="sheet-title">${esc(title)}</h2>
      <p class="muted">${esc(message)}</p>
      <div class="row gap mt">
        <button class="btn btn-ghost grow" data-no>Cancel</button>
        <button class="btn ${danger ? 'btn-danger' : 'btn-primary'} grow" data-yes>${esc(confirm)}</button>
      </div>`;
    $('[data-no]', el).onclick = () => close(false);
    $('[data-yes]', el).onclick = () => close(true);
  }).then((v) => !!v);
}

// ---------- confetti ----------

export function confetti({ count = 140, colors = ['#d4ff3a', '#6fb6ff', '#ff5d7a', '#ffd34d', '#c084fc'] } = {}) {
  const c = document.createElement('canvas');
  c.className = 'confetti';
  const dpr = window.devicePixelRatio || 1;
  c.width = innerWidth * dpr;
  c.height = innerHeight * dpr;
  document.body.appendChild(c);
  const ctx = c.getContext('2d');
  ctx.scale(dpr, dpr);
  const parts = Array.from({ length: count }, () => ({
    x: innerWidth / 2 + (Math.random() - 0.5) * 80,
    y: innerHeight * 0.35,
    vx: (Math.random() - 0.5) * 14,
    vy: -Math.random() * 14 - 4,
    r: Math.random() * Math.PI,
    vr: (Math.random() - 0.5) * 0.4,
    w: 6 + Math.random() * 6,
    h: 8 + Math.random() * 8,
    color: colors[Math.floor(Math.random() * colors.length)],
  }));
  const startT = performance.now();
  const frame = (t) => {
    ctx.clearRect(0, 0, innerWidth, innerHeight);
    for (const p of parts) {
      p.vy += 0.35;
      p.vx *= 0.99;
      p.x += p.vx;
      p.y += p.vy;
      p.r += p.vr;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.r);
      ctx.fillStyle = p.color;
      ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
      ctx.restore();
    }
    if (t - startT < 3200) requestAnimationFrame(frame);
    else c.remove();
  };
  requestAnimationFrame(frame);
}

// ---------- misc ----------

export function ring({ value, max, size = 140, stroke = 12, color = 'var(--accent)', track = 'var(--track)', children = '' }) {
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const pct = max > 0 ? Math.min(1, value / max) : 0;
  const over = max > 0 && value > max;
  return `
    <div class="ring" style="width:${size}px;height:${size}px">
      <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
        <circle cx="${size / 2}" cy="${size / 2}" r="${r}" stroke="${track}" stroke-width="${stroke}" fill="none"/>
        <circle class="ring-fg" cx="${size / 2}" cy="${size / 2}" r="${r}" stroke="${over ? 'var(--danger)' : color}" stroke-width="${stroke}" fill="none"
          stroke-linecap="round" stroke-dasharray="${circ}" stroke-dashoffset="${circ * (1 - pct)}" transform="rotate(-90 ${size / 2} ${size / 2})"/>
      </svg>
      <div class="ring-center">${children}</div>
    </div>`;
}

export function bar(value, max, color = 'var(--accent)') {
  const pct = max > 0 ? Math.min(100, (value / max) * 100) : 0;
  return `<div class="bar"><div class="bar-fill" style="width:${pct}%;background:${color}"></div></div>`;
}

export function debounce(fn, ms) {
  let t;
  return (...a) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...a), ms);
  };
}
