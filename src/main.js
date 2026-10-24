import { Capacitor } from '@capacitor/core';
import { App as CapApp } from '@capacitor/app';
import { SplashScreen } from '@capacitor/splash-screen';
import { StatusBar, Style } from '@capacitor/status-bar';
import { LocalNotifications } from '@capacitor/local-notifications';
import { app } from './app.js';
import { loadState, flush } from './store.js';
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

async function boot() {
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
    if (app.state.settings.reminders) {
      LocalNotifications.checkPermissions()
        .then((p) => (p.display === 'prompt' || p.display === 'prompt-with-rationale' ? LocalNotifications.requestPermissions() : p))
        .then(() => app.scheduleReminders())
        .catch(() => {});
    }
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
  console.error(e);
  document.querySelector('#app').innerHTML = `<div class="fatal"><h2>Something went wrong</h2><pre>${String(e?.stack || e).replace(/</g, '&lt;')}</pre></div>`;
});
