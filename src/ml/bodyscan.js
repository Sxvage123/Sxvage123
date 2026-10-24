// Turns a photo into body measurements + a "scan" visual for the results screen.

import { detectBody } from './vision.js';
import { measureMask, ScanError } from '../lib/bodyfat.js';
import { toCanvas } from './media.js';

export async function analyzeBodyPhoto(source, view = 'front') {
  const canvas = source instanceof HTMLCanvasElement ? source : toCanvas(source, 1280);
  const { landmarks, mask, width, height } = await detectBody(canvas);
  if (!landmarks) throw new ScanError('no_person', 'No person detected. Stand 2–3 m from the camera with your whole body in frame and good lighting.');
  if (!mask) throw new ScanError('no_mask', 'Body outline could not be detected. Try a plainer background.');
  const m = measureMask({ mask, width, height, landmarks, view });
  return { measurement: m, overlay: renderOverlay(canvas, mask, width, height, m) };
}

// Draws the photo with a neon body outline, height markers and the measured waist line.
function renderOverlay(canvas, mask, mw, mh, m) {
  const out = document.createElement('canvas');
  const scale = Math.min(1, 720 / Math.max(canvas.width, canvas.height));
  out.width = Math.round(canvas.width * scale);
  out.height = Math.round(canvas.height * scale);
  const ctx = out.getContext('2d');
  ctx.drawImage(canvas, 0, 0, out.width, out.height);
  ctx.fillStyle = 'rgba(5,7,12,0.45)';
  ctx.fillRect(0, 0, out.width, out.height);

  // Mask tint
  const tint = document.createElement('canvas');
  tint.width = mw;
  tint.height = mh;
  const tctx = tint.getContext('2d');
  const img = tctx.createImageData(mw, mh);
  for (let i = 0; i < mw * mh; i++) {
    const v = mask[i];
    if (v > 0.5) {
      // edge detection for a bright outline
      const edge = mask[i - 1] <= 0.5 || mask[i + 1] <= 0.5 || mask[i - mw] <= 0.5 || mask[i + mw] <= 0.5;
      img.data[i * 4] = edge ? 212 : 120;
      img.data[i * 4 + 1] = 255;
      img.data[i * 4 + 2] = edge ? 58 : 160;
      img.data[i * 4 + 3] = edge ? 255 : 60;
    }
  }
  tctx.putImageData(img, 0, 0);
  ctx.drawImage(tint, 0, 0, out.width, out.height);

  const sx = out.width / mw;
  const sy = out.height / mh;
  ctx.lineWidth = 2;
  ctx.setLineDash([6, 6]);
  ctx.strokeStyle = 'rgba(255,255,255,0.7)';
  for (const y of [m.top, m.bottom]) {
    ctx.beginPath();
    ctx.moveTo(0, y * sy);
    ctx.lineTo(out.width, y * sy);
    ctx.stroke();
  }
  ctx.setLineDash([]);
  // waist band
  const wy = m.waistY * sy;
  const half = (m.waistPx / 2) * sx;
  ctx.strokeStyle = '#ff5d7a';
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(m.centerX * sx - half, wy);
  ctx.lineTo(m.centerX * sx + half, wy);
  ctx.stroke();
  ctx.fillStyle = '#ff5d7a';
  for (const x of [m.centerX * sx - half, m.centerX * sx + half]) {
    ctx.beginPath();
    ctx.arc(x, wy, 5, 0, Math.PI * 2);
    ctx.fill();
  }
  return out.toDataURL('image/jpeg', 0.8);
}
