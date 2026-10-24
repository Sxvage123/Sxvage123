// Bundles the app into www/ (what Capacitor packages into the APK).
import { build } from 'esbuild';
import { cpSync, mkdirSync, rmSync, existsSync, copyFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'www');
const watch = process.argv.includes('--watch');

rmSync(out, { recursive: true, force: true });
mkdirSync(join(out, 'models'), { recursive: true });
mkdirSync(join(out, 'mediapipe'), { recursive: true });

copyFileSync(join(root, 'src/index.html'), join(out, 'index.html'));
cpSync(join(root, 'assets/icons'), join(out, 'icons'), { recursive: true });

// MediaPipe WASM runtime. Only the SIMD build: every supported Android WebView (Chrome 91+) has SIMD.
const wasm = join(root, 'node_modules/@mediapipe/tasks-vision/wasm');
for (const f of ['vision_wasm_internal.js', 'vision_wasm_internal.wasm']) {
  copyFileSync(join(wasm, f), join(out, 'mediapipe', f));
}

// On-device models (downloaded by scripts/fetch-models.mjs).
for (const f of ['food_V1.tflite', 'efficientnet_lite0.tflite', 'pose_landmarker_full.task']) {
  const src = join(root, 'models-cache', f);
  if (!existsSync(src)) {
    console.error(`Missing model ${f}. Run: npm run models`);
    process.exit(1);
  }
  copyFileSync(src, join(out, 'models', f));
}

const opts = {
  entryPoints: { app: join(root, 'src/main.js') },
  bundle: true,
  format: 'esm',
  target: ['chrome100'],
  outdir: out,
  minify: !watch,
  sourcemap: watch ? 'inline' : false,
  loader: { '.css': 'css' },
  logLevel: 'info',
};
await build({ ...opts, entryPoints: { app: join(root, 'src/main.js'), 'app-styles': join(root, 'src/styles.css') } });
// esbuild names the CSS output after its entry; keep a stable name for index.html.
cpSync(join(out, 'app-styles.css'), join(out, 'app.css'));
rmSync(join(out, 'app-styles.css'));
rmSync(join(out, 'app-styles.js'), { force: true });
console.log('Built www/');
