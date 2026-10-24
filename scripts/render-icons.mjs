// Renders assets/icon.svg to PNGs (web + Android launcher icons) using Playwright's Chromium.
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright'); // pre-installed globally; set NODE_PATH=$(npm root -g)
import { readFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const svg = readFileSync(join(root, 'assets/icon.svg'), 'utf8');
// Foreground-only version for Android adaptive icons (transparent bg, shield in the 66% safe zone).
const fg = svg.replace(/<rect[^>]*fill="url\(#bg\)"\/>/, '').replace('scale(3.3)', 'scale(2.35)');
const browser = await chromium.launch();
const page = await browser.newPage();
async function render(markup, size, out, transparent = false) {
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(`<html><body style="margin:0;background:${transparent ? 'transparent' : '#07090d'}">${markup.replace('<svg ', `<svg width="${size}" height="${size}" `)}</body></html>`);
  mkdirSync(dirname(out), { recursive: true });
  await page.screenshot({ path: out, omitBackground: transparent });
}
await render(svg, 192, join(root, 'assets/icons/icon-192.png'));
await render(svg, 512, join(root, 'assets/icons/icon-512.png'));
const res = join(root, 'android/app/src/main/res');
if (existsSync(res)) {
  const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
  for (const [d, k] of Object.entries(dens)) {
    await render(svg, 48 * k, join(res, `mipmap-${d}/ic_launcher.png`));
    await render(svg.replace('<rect width="512" height="512"', '<rect width="512" height="512" rx="256"'), 48 * k, join(res, `mipmap-${d}/ic_launcher_round.png`), true);
    await render(fg, 108 * k, join(res, `mipmap-${d}/ic_launcher_foreground.png`), true);
  }
  // Splash: icon centred on dark background.
  for (const [d, k] of Object.entries(dens)) {
    for (const orient of ['port', 'land']) {
      const w = (orient === 'port' ? 320 : 480) * k;
      const h = (orient === 'port' ? 480 : 320) * k;
      await page.setViewportSize({ width: w, height: h });
      await page.setContent(`<html><body style="margin:0;background:#0b0d12;display:grid;place-items:center;height:100vh">${fg.replace('<svg ', `<svg width="${Math.min(w, h) * 0.6}" height="${Math.min(w, h) * 0.6}" `)}</body></html>`);
      const out = join(res, `drawable-${orient}-${d}/splash.png`);
      mkdirSync(dirname(out), { recursive: true });
      await page.screenshot({ path: out });
    }
  }
  await page.setViewportSize({ width: 480, height: 480 });
  await page.setContent(`<html><body style="margin:0;background:#0b0d12;display:grid;place-items:center;height:100vh">${fg.replace('<svg ', '<svg width="300" height="300" ')}</body></html>`);
  await page.screenshot({ path: join(res, 'drawable/splash.png') });
}
await browser.close();
console.log('icons rendered');
