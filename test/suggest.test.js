import { test } from 'node:test';
import assert from 'node:assert/strict';
import { suggestFoods } from '../src/lib/suggest.js';

test('suggests high-protein foods that fit the remaining calories', () => {
  const s = suggestFoods(400, 60);
  assert.equal(s.length, 3);
  for (const f of s) {
    assert.ok(f.calories <= 420);
    assert.ok(f.protein / f.calories > 0.08, f.name);
  }
  assert.deepEqual(suggestFoods(80, 50), []);
});
