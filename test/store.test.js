import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sanitizeState } from '../src/store.js';

test('sanitizeState strips non-image thumbs and odd values', () => {
  const s = sanitizeState({
    meals: [{ id: 'a', date: '2026-01-01', time: 't', name: 'x', calories: '100', thumb: 'x" onerror="alert(1)' }],
    scans: [{ id: 'b', date: '2026-01-01', time: 't', bodyFat: 20, low: '<b>', thumb: 'data:image/jpeg;base64,AAAA' }],
    challenges: { '2026-01-01': { title: 't', difficulty: '"><img src=x onerror=1>', xp: 99999 }, bad: {} },
  });
  assert.equal(s.meals[0].thumb, null);
  assert.equal(s.meals[0].calories, 0);
  assert.equal(s.scans[0].low, 0);
  assert.equal(s.scans[0].thumb, 'data:image/jpeg;base64,AAAA');
  assert.equal(s.challenges['2026-01-01'].difficulty, 'medium');
  assert.equal(s.challenges['2026-01-01'].xp, 400);
  assert.equal(s.challenges.bad, undefined);
});
