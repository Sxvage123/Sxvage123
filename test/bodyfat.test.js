import { test } from 'node:test';
import assert from 'node:assert/strict';
import { rfm, navy, ellipseCircumference, measureMask, estimateFromPhotos, estimateFromTape, categoryFor, ScanError } from '../src/lib/bodyfat.js';
import { computeTargets } from '../src/lib/nutrition.js';
import { foodForLabel, searchFoods, FOODS } from '../src/lib/foods.js';

test('RFM matches published formula', () => {
  // 180 cm man, 90 cm waist: 64 - 20*2 = 24
  assert.equal(rfm('male', 180, 90), 24);
  assert.equal(rfm('female', 165, 75), 76 - 20 * (165 / 75));
});

test('Navy formula sane', () => {
  const m = navy('male', 178, 86, 38);
  assert.ok(m > 14 && m < 22, String(m));
  const f = navy('female', 165, 74, 32, 98);
  assert.ok(f > 22 && f < 32, String(f));
});

test('ellipse circumference: circle case', () => {
  assert.ok(Math.abs(ellipseCircumference(10, 10) - Math.PI * 10) < 1e-9);
});

// Synthetic person: an upright "body" rectangle with a narrower waist, 1000 px tall image.
function synthetic({ w = 400, h = 1000, top = 100, bottom = 900, torsoW = 120, waistW = 100, armsTouch = false }) {
  const mask = new Float32Array(w * h);
  const cx = w / 2;
  const fill = (y, half) => {
    for (let x = Math.round(cx - half); x <= Math.round(cx + half); x++) mask[y * w + x] = 1;
  };
  const shoulderY = top + 0.18 * (bottom - top);
  const hipY = top + 0.48 * (bottom - top);
  for (let y = top; y <= bottom; y++) {
    let half = torsoW / 2;
    if (y < shoulderY) half = 30;
    else if (y > shoulderY + 0.6 * (hipY - shoulderY) && y < hipY) half = waistW / 2;
    if (armsTouch && y > shoulderY && y < hipY) half += 30;
    fill(y, half);
  }
  const lm = Array.from({ length: 33 }, () => ({ x: 0.5, y: 0.5, visibility: 0.9 }));
  lm[11] = { x: (cx + 55) / w, y: shoulderY / h, visibility: 0.99 };
  lm[12] = { x: (cx - 55) / w, y: shoulderY / h, visibility: 0.99 };
  lm[23] = { x: (cx + 30) / w, y: hipY / h, visibility: 0.99 };
  lm[24] = { x: (cx - 30) / w, y: hipY / h, visibility: 0.99 };
  for (const i of [27, 28, 29, 30, 31, 32]) lm[i] = { x: 0.5, y: (bottom - 5) / h, visibility: 0.9 };
  // arms out to the side (A-pose) unless touching
  for (const i of [13, 14, 15, 16]) lm[i] = { x: armsTouch ? 0.5 + (i % 2 ? 0.1 : -0.1) : i % 2 ? 0.05 : 0.95, y: (shoulderY + 0.75 * (hipY - shoulderY)) / h, visibility: 0.9 };
  return { mask, width: w, height: h, landmarks: lm };
}

test('measureMask finds height and waist', () => {
  const m = measureMask(synthetic({}));
  assert.equal(m.heightPx, 800);
  assert.ok(Math.abs(m.waistPx - 101) <= 2, String(m.waistPx));
  assert.deepEqual(m.warnings, []);
});

test('measureMask warns when arms touch torso', () => {
  const m = measureMask(synthetic({ armsTouch: true }));
  assert.ok(m.warnings.includes('arms'));
});

test('measureMask errors when feet are cut off', () => {
  const s = synthetic({ bottom: 999 });
  for (const i of [27, 28, 29, 30, 31, 32]) s.landmarks[i].y = 0.995;
  assert.throws(() => measureMask(s), (e) => e instanceof ScanError && e.code === 'feet_cut');
});

test('estimateFromPhotos produces plausible numbers', () => {
  // 800 px = 180 cm -> waist 101 px ≈ 22.7 cm wide?? that is a skinny synthetic; scale to realistic:
  const front = { waistPx: 140, heightPx: 800, warnings: [] }; // 31.5 cm wide
  const est = estimateFromPhotos({ sex: 'male', heightCm: 180, front });
  assert.ok(est.waistCm > 80 && est.waistCm < 95, String(est.waistCm));
  assert.ok(est.bodyFat > 15 && est.bodyFat < 26, String(est.bodyFat));
  const side = { waistPx: 110, heightPx: 800, warnings: [] };
  const est2 = estimateFromPhotos({ sex: 'male', heightCm: 180, front, side });
  assert.equal(est2.method, 'photo2');
});

test('tape estimate blends RFM and Navy', () => {
  const e = estimateFromTape({ sex: 'male', heightCm: 178, waistCm: 86, neckCm: 38 });
  assert.equal(e.method, 'tape_navy');
  assert.ok(e.bodyFat > 14 && e.bodyFat < 24);
  assert.equal(categoryFor('male', 12).key, 'athlete');
  assert.equal(categoryFor('female', 35).key, 'high');
});

test('targets: cut is below TDEE, respects floor', () => {
  const t = computeTargets({ sex: 'male', age: 25, heightCm: 180, weightKg: 80, activity: 1.55, goal: 'cut' });
  assert.ok(t.calories < t.tdee);
  assert.ok(t.protein >= 170);
  const tiny = computeTargets({ sex: 'female', age: 60, heightCm: 150, weightKg: 45, activity: 1.2, goal: 'cut' });
  assert.equal(tiny.calories, 1200);
});

test('food mapping', () => {
  assert.equal(foodForLabel('Hamburger').food.name, 'Hamburger');
  assert.match(foodForLabel('New York-style pizza').food.name, /pizza/i);
  assert.equal(foodForLabel('Fried rice').food.name, 'Fried rice');
  const est = foodForLabel('Tripe soup');
  assert.equal(est.estimated, true);
  assert.equal(est.food.calories, 240);
  assert.ok(foodForLabel('Zzzunknown').food.calories > 0);
  assert.equal(searchFoods('chicken breast')[0].name, 'Grilled chicken breast');
  assert.equal(searchFoods('banana')[0].name, 'Banana');
  assert.ok(FOODS.length > 200);
  for (const f of FOODS) {
    const kcal = f.protein * 4 + f.carbs * 4 + f.fat * 9;
    // macros roughly consistent with calories (alcohol drinks excluded)
    if (!['Beer', 'Light beer', 'Wine'].includes(f.name) && f.calories > 30) assert.ok(Math.abs(kcal - f.calories) / f.calories < 0.3, `${f.name} ${kcal} vs ${f.calories}`);
  }
});

test('no calorie deficit for under-18s', () => {
  const teen = computeTargets({ sex: 'male', age: 16, heightCm: 175, weightKg: 70, activity: 1.55, goal: 'cut' });
  assert.ok(teen.calories >= teen.tdee - 10);
});
