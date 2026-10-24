// Downloads the free on-device ML models into models-cache/ (git-ignored).
import { mkdirSync, existsSync, writeFileSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dir = join(root, 'models-cache');
mkdirSync(dir, { recursive: true });

const MODELS = {
  // Google AIY food classifier (~2,000 dishes), Apache-2.0.
  'food_V1.tflite': 'https://tfhub.dev/google/lite-model/aiy/vision/classifier/food_V1/1?lite-format=tflite',
  // MediaPipe EfficientNet-Lite0 (ImageNet) — strong on single fruits & vegetables, Apache-2.0.
  'efficientnet_lite0.tflite': 'https://storage.googleapis.com/mediapipe-models/image_classifier/efficientnet_lite0/int8/latest/efficientnet_lite0.tflite',
  // MediaPipe pose landmarker with segmentation output, Apache-2.0.
  'pose_landmarker_full.task': 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task',
};

for (const [name, url] of Object.entries(MODELS)) {
  const path = join(dir, name);
  if (existsSync(path) && statSync(path).size > 1e6) {
    console.log(`✓ ${name} (cached)`);
    continue;
  }
  process.stdout.write(`↓ ${name} … `);
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`${name}: HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  writeFileSync(path, buf);
  console.log(`${(buf.length / 1e6).toFixed(1)} MB`);
}
