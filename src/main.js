import { Capacitor } from '@capacitor/core';
import { App as CapApp } from '@capacitor/app';
import { SplashScreen } from '@capacitor/splash-screen';
import { StatusBar, Style } from '@capacitor/status-bar';
import { app } from './app.js';
import { loadState, flush, saveState } from './store.js';
import { migrateInlineThumbs, cleanupThumbs } from './thumbs.js';
import { renderOnboarding } from './ui/onboarding.js';
import { renderHome } from './ui/home.js';
import { renderFood } from './ui/food.js';
import { renderScan } from './ui/scan.js';
import { renderProgress } from './ui/progress.js';
import { renderMe } from './ui/me.js';
import { closeTopOverlay, toast } from './ui/dom.js';
import { closeLiveCam } from './ui/livecam.js';
import { preloadModels } from './ml/vision.js';
import { dayKey } from './lib/dates.js';
import { initDiag, logDiag } from './diag.js';

async function boot() {
  await initDiag();
  const state = await loadState();
  app.init(state, {
    onboarding: renderOnboarding,
    home: renderHome,
    food: renderFood,
    scan: renderScan,
    progress: renderProgress,
    me: renderMe,
  });
  app.render();
  app.celebrate();
  migrateInlineThumbs(app.state)
    .then((changed) => changed && saveState(app.state))
    .then(() => cleanupThumbs(app.state))
    .catch(() => {});

  if (Capacitor.isNativePlatform()) {
    StatusBar.setStyle({ style: Style.Dark }).catch(() => {});
    SplashScreen.hide().catch(() => {});
    let lastBack = 0;
    CapApp.addListener('backButton', () => {
      if (closeLiveCam() || closeTopOverlay()) return;
      if (app.state.profile && app.tab !== 'home') return app.go('home');
      const now = Date.now();
      if (now - lastBack < 1800) CapApp.exitApp();
      else toast('Press back again to exit');
      lastBack = now;
    });
    CapApp.addListener('pause', () => flush());
    CapApp.addListener('resume', () => {
      // A new day may have started while the app was in the background.
      if (dayKey() !== app.today) {
        app.refresh();
        app.render();
        app.celebrate();
      }
      app.scheduleReminders();
    });
    // Ask for notification permission only once the user is set up (onboarding asks right after it finishes).
    if (app.state.profile && app.state.settings.reminders) app.ensureNotificationPermission();
  }
  window.addEventListener('beforeunload', () => flush());
  document.addEventListener('visibilitychange', () => document.visibilityState === 'hidden' && flush());
  setTimeout(preloadModels, 2500);
  // Midnight rollover while the app stays open.
  setInterval(() => {
    if (dayKey() !== app.today) {
      app.refresh();
      app.render();
    }
  }, 60000);
}

boot().catch((e) => {
  logDiag('boot', e);
  console.error(e);
  document.querySelector('#app').innerHTML = `<div class="fatal"><h2>Something went wrong</h2><pre>${String(e?.stack || e).replace(/</g, '&lt;')}</pre></div>`;
});
