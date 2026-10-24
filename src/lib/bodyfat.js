// Body-fat estimation math. Pure functions only — the camera/ML side lives in ../ml/bodyscan.js.
//
// Method: a full-body photo gives a person segmentation mask plus pose landmarks. Knowing your
// real height lets us convert pixels to centimetres, measure your waist width (and depth, from an
// optional side photo), approximate waist circumference as an ellipse, then apply the Relative Fat
// Mass formula (Woolcott & Bergman 2018, validated against DXA):
//   RFM = 64 − 20 × (height / waist)  (men)
//   RFM = 76 − 20 × (height / waist)  (women)
// With tape measurements we use RFM directly, or the U.S. Navy formula when neck (and hip) are given.

export const CATEGORIES = {
  male: [
    { max: 5.9, key: 'essential', label: 'Essential fat', color: '#ff5d7a' },
    { max: 13.9, key: 'athlete', label: 'Athlete', color: '#d4ff3a' },
    { max: 17.9, key: 'fitness', label: 'Fitness', color: '#5ee6d0' },
    { max: 24.9, key: 'average', label: 'Average', color: '#ffd34d' },
    { max: Infinity, key: 'high', label: 'Above average', color: '#ff9f43' },
  ],
  female: [
    { max: 13.9, key: 'essential', label: 'Essential fat', color: '#ff5d7a' },
    { max: 20.9, key: 'athlete', label: 'Athlete', color: '#d4ff3a' },
    { max: 24.9, key: 'fitness', label: 'Fitness', color: '#5ee6d0' },
    { max: 31.9, key: 'average', label: 'Average', color: '#ffd34d' },
    { max: Infinity, key: 'high', label: 'Above average', color: '#ff9f43' },
  ],
};

export function categoryFor(sex, bf) {
  const list = CATEGORIES[sex === 'female' ? 'female' : 'male'];
  return list.find((c) => bf <= c.max);
}

export const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

export function rfm(sex, heightCm, waistCm) {
  const base = sex === 'female' ? 76 : 64;
  return clamp(base - 20 * (heightCm / waistCm), 3, 60);
}

export function navy(sex, heightCm, waistCm, neckCm, hipCm) {
  if (sex === 'female') {
    if (!hipCm) return null;
    const v = waistCm + hipCm - neckCm;
    if (v <= 0) return null;
    return clamp(495 / (1.29579 - 0.35004 * Math.log10(v) + 0.221 * Math.log10(heightCm)) - 450, 3, 60);
  }
  const v = waistCm - neckCm;
  if (v <= 0) return null;
  return clamp(495 / (1.0324 - 0.19077 * Math.log10(v) + 0.15456 * Math.log10(heightCm)) - 450, 3, 60);
}

// Ramanujan's approximation for the perimeter of an ellipse with full axes w × d.
export function ellipseCircumference(widthCm, depthCm) {
  const a = widthCm / 2;
  const b = depthCm / 2;
  const h = ((a - b) * (a - b)) / ((a + b) * (a + b));
  return Math.PI * (a + b) * (1 + (3 * h) / (10 + Math.sqrt(4 - 3 * h)));
}

// Typical waist depth/width ratio when no side photo is given.
export const DEFAULT_DEPTH_RATIO = { male: 0.8, female: 0.76 };
// A real waist cross-section is a little "boxier" than an ellipse.
export const SHAPE_FACTOR = 1.02;

export function estimateWaistCm({ sex, widthCm, depthCm }) {
  const depth = depthCm || widthCm * DEFAULT_DEPTH_RATIO[sex === 'female' ? 'female' : 'male'];
  return ellipseCircumference(widthCm, depth) * SHAPE_FACTOR;
}

// ---------- mask measurement ----------
//
// mask: Float32Array/Uint8Array of length w*h with person-probability (0..1 or 0..255)
// lm: 33 MediaPipe pose landmarks, normalised {x, y, visibility}

const L = { nose: 0, lShoulder: 11, rShoulder: 12, lElbow: 13, rElbow: 14, lWrist: 15, rWrist: 16, lHip: 23, rHip: 24, lAnkle: 27, rAnkle: 28, lHeel: 29, rHeel: 30, lFoot: 31, rFoot: 32 };

const visible = (p, min = 0.4) => p && (p.visibility === undefined || p.visibility >= min);

export class ScanError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function makeTest(mask, threshold) {
  const scale = mask instanceof Uint8Array || mask instanceof Uint8ClampedArray ? 255 : 1;
  const t = threshold * scale;
  return (i) => mask[i] >= t;
}

// Width of the contiguous mask run on row y that contains (or is nearest to) x.
export function runAt(mask, w, y, x, test) {
  const row = y * w;
  let cx = Math.round(x);
  if (!test(row + cx)) {
    // Search outward a little in case the centre line falls in a gap (e.g. between legs).
    let found = -1;
    for (let d = 1; d < w * 0.06 && found < 0; d++) {
      if (cx - d >= 0 && test(row + cx - d)) found = cx - d;
      else if (cx + d < w && test(row + cx + d)) found = cx + d;
    }
    if (found < 0) return null;
    cx = found;
  }
  let l = cx;
  let r = cx;
  while (l > 0 && test(row + l - 1)) l--;
  while (r < w - 1 && test(row + r + 1)) r++;
  return { left: l, right: r, width: r - l + 1 };
}

function verticalExtent(mask, w, h, x0, x1, test) {
  let top = -1;
  let bottom = -1;
  const lo = Math.max(0, Math.floor(x0));
  const hi = Math.min(w - 1, Math.ceil(x1));
  for (let y = 0; y < h && top < 0; y++) for (let x = lo; x <= hi; x++) if (test(y * w + x)) { top = y; break; }
  for (let y = h - 1; y >= 0 && bottom < 0; y--) for (let x = lo; x <= hi; x++) if (test(y * w + x)) { bottom = y; break; }
  return { top, bottom };
}

const median = (arr) => {
  const s = [...arr].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
};

// Measures one photo. view: 'front' | 'side'. Returns pixel measurements + warnings.
export function measureMask({ mask, width: w, height: h, landmarks: lm, view = 'front', threshold = 0.5 }) {
  if (!lm || lm.length < 33) throw new ScanError('no_person', 'No person detected. Stand fully in frame with good lighting.');
  const test = makeTest(mask, threshold);
  const P = (i) => ({ x: lm[i].x * w, y: lm[i].y * h, v: lm[i].visibility });

  const shoulders = [lm[L.lShoulder], lm[L.rShoulder]].filter((p) => visible(p));
  const hips = [lm[L.lHip], lm[L.rHip]].filter((p) => visible(p));
  if (!shoulders.length || !hips.length) throw new ScanError('no_torso', 'Could not find your shoulders and hips. Face the camera with your torso clearly visible.');
  const feet = [L.lAnkle, L.rAnkle, L.lHeel, L.rHeel, L.lFoot, L.rFoot].map((i) => lm[i]).filter((p) => visible(p, 0.3));
  if (!feet.length) throw new ScanError('no_feet', 'Your feet are cut off. Step back so your whole body — head to toes — is in the photo.');

  const shoulderY = (shoulders.reduce((s, p) => s + p.y, 0) / shoulders.length) * h;
  const hipY = (hips.reduce((s, p) => s + p.y, 0) / hips.length) * h;
  const centerX = (([...shoulders, ...hips].reduce((s, p) => s + p.x, 0)) / (shoulders.length + hips.length)) * w;
  if (hipY - shoulderY < h * 0.08) throw new ScanError('too_far', 'You are too far away or lying down. Stand upright and fill most of the frame.');

  // Vertical extent: search a column band around the body centre to ignore stray background blobs.
  const band = Math.max(8, (hipY - shoulderY) * 0.9);
  const { top, bottom } = verticalExtent(mask, w, h, centerX - band, centerX + band, test);
  if (top < 0) throw new ScanError('no_person', 'No person detected. Try a plainer background and brighter light.');
  if (top <= 1) throw new ScanError('head_cut', 'The top of your head is cut off. Tilt the phone or step back.');
  const footY = Math.max(...feet.map((p) => p.y * h));
  if (bottom >= h - 2 && footY > h * 0.97) throw new ScanError('feet_cut', 'Your feet touch the bottom edge. Step back a little so there is space under your feet.');
  const heightPx = bottom - top;
  if (heightPx < h * 0.45) throw new ScanError('too_far', 'You are too far from the camera. Move closer so your body fills most of the frame.');

  // Waist band: around the iliac crest, ~70–85% of the way from shoulders to hip joints.
  const widths = [];
  const warnings = new Set();
  const y0 = Math.round(shoulderY + 0.7 * (hipY - shoulderY));
  const y1 = Math.round(shoulderY + 0.86 * (hipY - shoulderY));
  const shoulderRun = runAt(mask, w, Math.round(shoulderY + 0.12 * (hipY - shoulderY)), centerX, test);
  const armPts = [L.lElbow, L.rElbow, L.lWrist, L.rWrist].map((i) => (visible(lm[i]) ? P(i) : null)).filter(Boolean);
  for (let y = y0; y <= y1; y++) {
    const run = runAt(mask, w, y, centerX, test);
    if (!run) continue;
    // Arms touching the torso widen the run; flag it.
    for (const a of armPts) {
      if (Math.abs(a.y - y) < (hipY - shoulderY) * 0.18 && a.x >= run.left - 2 && a.x <= run.right + 2) warnings.add('arms');
    }
    widths.push(run.width);
  }
  if (widths.length < 3) throw new ScanError('no_waist', 'Could not measure your waist. Wear fitted clothing and stand against a plain background.');
  const waistPx = median(widths);
  if (view === 'front' && shoulderRun && waistPx > shoulderRun.width * 1.15) warnings.add('arms');

  return {
    view,
    heightPx,
    waistPx,
    shoulderPx: shoulderRun ? shoulderRun.width : null,
    top,
    bottom,
    waistY: (y0 + y1) / 2,
    waistBand: [y0, y1],
    centerX,
    warnings: [...warnings],
  };
}

export const WARNING_TEXT = {
  arms: 'Your arms may be touching your sides, which makes your waist read wider. Hold them out in an A-pose for the most accurate result.',
};

// Combines front (+ optional side) measurements into a body-fat estimate.
export function estimateFromPhotos({ sex, heightCm, front, side, calibration = 1 }) {
  const widthCm = (front.waistPx / front.heightPx) * heightCm;
  const depthCm = side ? (side.waistPx / side.heightPx) * heightCm : null;
  const rawWaist = estimateWaistCm({ sex, widthCm, depthCm });
  const waistCm = rawWaist * clamp(calibration || 1, 0.8, 1.25);
  const bodyFat = rfm(sex, heightCm, waistCm);
  const margin = (side ? 3.5 : 4.5) + (front.warnings.length ? 1 : 0);
  return {
    method: side ? 'photo2' : 'photo',
    bodyFat: round1(bodyFat),
    low: round1(Math.max(3, bodyFat - margin)),
    high: round1(bodyFat + margin),
    waistCm: round1(waistCm),
    rawWaistCm: round1(rawWaist),
    widthCm: round1(widthCm),
    depthCm: depthCm ? round1(depthCm) : null,
    whtr: round2(waistCm / heightCm),
    confidence: side && !front.warnings.length ? 'medium-high' : 'medium',
  };
}

export function estimateFromTape({ sex, heightCm, waistCm, neckCm, hipCm }) {
  const r = rfm(sex, heightCm, waistCm);
  const n = neckCm ? navy(sex, heightCm, waistCm, neckCm, hipCm) : null;
  const bodyFat = n !== null ? (r + n) / 2 : r;
  const margin = n !== null ? 3 : 3.5;
  return {
    method: n !== null ? 'tape_navy' : 'tape',
    bodyFat: round1(bodyFat),
    low: round1(Math.max(3, bodyFat - margin)),
    high: round1(bodyFat + margin),
    waistCm: round1(waistCm),
    whtr: round2(waistCm / heightCm),
    rfm: round1(r),
    navy: n !== null ? round1(n) : null,
    confidence: 'high',
  };
}

// Waist-to-height ratio guidance (keep your waist under half your height).
export function whtrLabel(whtr) {
  if (whtr < 0.43) return { label: 'Very lean', color: '#5ee6d0' };
  if (whtr < 0.5) return { label: 'Healthy', color: '#d4ff3a' };
  if (whtr < 0.58) return { label: 'Elevated', color: '#ffd34d' };
  return { label: 'High risk', color: '#ff5d7a' };
}

export const round1 = (v) => Math.round(v * 10) / 10;
export const round2 = (v) => Math.round(v * 100) / 100;

// Lean mass and "what it takes" helpers for the result screen.
export function leanMassKg(weightKg, bf) {
  return weightKg * (1 - bf / 100);
}

export function weightAtBodyFat(weightKg, bf, targetBf) {
  // Assumes lean mass is preserved.
  return leanMassKg(weightKg, bf) / (1 - targetBf / 100);
}
