// Food log + the add-food sheet (snap with on-device AI, search, barcode, quick add).

import { esc, fmt, ring, sheet, toast, haptic, confirmDialog, debounce } from './dom.js';
import { dayTotals, mealsOn } from '../lib/game.js';
import { addDays, formatDay } from '../lib/dates.js';
import { FOODS, FOOD_CATEGORIES, searchFoods, foodForLabel, IMAGENET_FOODS } from '../lib/foods.js';
import { pickImage, toCanvas, thumbnail, isNative } from '../ml/media.js';
import { classifyFood } from '../ml/vision.js';
import { uid } from '../store.js';
import { storeThumb, deleteThumb } from '../thumbs.js';
import { lookupBarcode, scanBarcode, searchOnline } from './barcode.js';

export const MEAL_TYPES = [
  { id: 'breakfast', label: 'Breakfast', icon: '🌅' },
  { id: 'lunch', label: 'Lunch', icon: '☀️' },
  { id: 'dinner', label: 'Dinner', icon: '🌙' },
  { id: 'snack', label: 'Snacks', icon: '🍿' },
];

export function defaultMealType(date = new Date()) {
  const h = date.getHours();
  if (h < 10.5) return 'breakfast';
  if (h < 15) return 'lunch';
  if (h < 21) return 'dinner';
  return 'snack';
}

let viewDate = null;

export function renderFood(root, app) {
  const { state } = app;
  if (!viewDate || viewDate > app.today) viewDate = app.today;
  const p = state.profile;
  const t = dayTotals(state, viewDate);
  const meals = [...mealsOn(state, viewDate)].sort((a, b) => a.time.localeCompare(b.time));
  const remaining = p.calorieGoal - Math.round(t.calories);

  root.innerHTML = `
  <header class="page-head">
    <h1 class="h1">Food log</h1>
  </header>
  <div class="date-nav">
    <button class="icon-btn" data-day="-1" aria-label="Previous day">‹</button>
    <b>${esc(formatDay(viewDate, app.today))}</b>
    <button class="icon-btn" data-day="1" ${viewDate >= app.today ? 'disabled' : ''} aria-label="Next day">›</button>
  </div>
  ${viewDate < app.today ? '<div class="banner subtle">Editing a past day. Back-dated entries count toward your nutrition stats but don’t earn XP or streak days.</div>' : ''}
  <section class="card food-summary">
    ${ring({ value: t.calories, max: p.calorieGoal, size: 112, stroke: 11, children: `<div class="ring-num sm">${fmt(Math.abs(remaining))}</div><div class="ring-label">${remaining >= 0 ? 'left' : 'over'}</div>` })}
    <div class="grow">
      <div class="sum-line"><span>Eaten</span><b>${fmt(t.calories)} kcal</b></div>
      <div class="sum-line"><span>Goal</span><b>${fmt(p.calorieGoal)} kcal</b></div>
      <div class="macro-chips">
        <span class="mchip p">P ${fmt(t.protein)}g</span><span class="mchip c">C ${fmt(t.carbs)}g</span><span class="mchip f">F ${fmt(t.fat)}g</span>
      </div>
    </div>
  </section>
  ${MEAL_TYPES.map((mt) => {
    const list = meals.filter((m) => (m.mealType || 'snack') === mt.id);
    const kcal = list.reduce((s, m) => s + m.calories, 0);
    const prev = list.length ? [] : mealsOn(state, addDays(viewDate, -1)).filter((m) => (m.mealType || 'snack') === mt.id);
    return `
    <section class="card meal-group">
      <div class="card-head"><h3>${mt.icon} ${mt.label}</h3><span class="muted small">${list.length ? `${fmt(kcal)} kcal` : ''}</span></div>
      ${list.map((m) => mealRow(m)).join('')}
      <div class="row">
        <button class="add-row grow" data-add-type="${mt.id}">＋ Add ${mt.label.toLowerCase()}</button>
        ${prev.length ? `<button class="repeat-btn" data-repeat="${mt.id}">↻ Same as yesterday · ${fmt(prev.reduce((a, m) => a + m.calories, 0))}</button>` : ''}
      </div>
    </section>`;
  }).join('')}
  <div class="spacer"></div>
  <button class="fab" data-fab aria-label="Add food">＋</button>`;

  root.querySelectorAll('[data-day]').forEach(
    (b) =>
      (b.onclick = () => {
        viewDate = addDays(viewDate, Number(b.dataset.day));
        if (viewDate > app.today) viewDate = app.today;
        app.render();
      }),
  );
  root.querySelectorAll('[data-add-type]').forEach((b) => (b.onclick = () => openAddFood(app, 'snap', { mealType: b.dataset.addType, date: viewDate })));
  root.querySelector('[data-fab]').onclick = () => openAddFood(app, 'snap', { date: viewDate });
  root.querySelectorAll('[data-meal]').forEach((b) => (b.onclick = () => editMeal(app, b.dataset.meal)));
  root.querySelectorAll('[data-repeat]').forEach(
    (b) =>
      (b.onclick = () => {
        const type = b.dataset.repeat;
        const prev = mealsOn(app.state, addDays(viewDate, -1)).filter((m) => (m.mealType || 'snack') === type);
        const time = viewDate === app.today ? new Date().toISOString() : `${viewDate}T12:00:00`;
        app.update((s) => {
          for (const m of prev) s.meals.push({ ...m, id: uid(), date: viewDate, time, loggedOn: app.today });
        });
        haptic('success');
        toast(`Logged ${prev.length} item${prev.length > 1 ? 's' : ''} from yesterday`, { icon: '↻' });
      }),
  );
}

function mealRow(m) {
  return `
  <button class="meal-row" data-meal="${esc(m.id)}">
    ${m.thumb ? `<img class="meal-thumb" src="${esc(m.thumb)}" alt=""/>` : `<div class="meal-thumb ph">${m.source === 'barcode' ? '▥' : '🍽️'}</div>`}
    <div class="grow left">
      <div class="meal-name">${esc(m.name)}</div>
      <div class="muted tiny">${esc(m.servingText || '')}${m.servingText ? ' · ' : ''}P ${fmt(m.protein)} · C ${fmt(m.carbs)} · F ${fmt(m.fat)}</div>
    </div>
    <b class="meal-kcal">${fmt(m.calories)}</b>
  </button>`;
}

// ---------- add food ----------

export function openAddFood(app, mode = 'snap', opts = {}) {
  const ctx = { mealType: opts.mealType || defaultMealType(), date: opts.date || app.today, mode };
  return sheet(
    (el, close) => {
      const draw = () => {
        el.innerHTML = `
        <div class="sheet-head">
          <h2 class="sheet-title">Add food</h2>
          <select class="select" data-type>${MEAL_TYPES.map((m) => `<option value="${m.id}" ${m.id === ctx.mealType ? 'selected' : ''}>${m.icon} ${m.label}</option>`).join('')}</select>
        </div>
        <div class="seg seg-4">
          ${[
            ['snap', '📸 Snap'],
            ['search', '🔎 Search'],
            ['barcode', '▥ Barcode'],
            ['quick', '✏️ Quick'],
          ]
            .map(([id, label]) => `<button class="seg-btn ${ctx.mode === id ? 'active' : ''}" data-mode="${id}">${label}</button>`)
            .join('')}
        </div>
        <div class="add-body" id="add-body"></div>`;
        el.querySelector('[data-type]').onchange = (e) => (ctx.mealType = e.target.value);
        el.querySelectorAll('[data-mode]').forEach(
          (b) =>
            (b.onclick = () => {
              ctx.mode = b.dataset.mode;
              draw();
            }),
        );
        const body = el.querySelector('#add-body');
        const done = (entries) => {
          logEntries(app, ctx, entries);
          close(true);
        };
        if (ctx.mode === 'snap') snapPane(body, app, ctx, done);
        else if (ctx.mode === 'search' && opts.foodName && !ctx.openedFood) {
          // Deep link from a suggestion: jump straight to the food's detail screen.
          ctx.openedFood = true;
          const food = FOODS.find((f) => f.name === opts.foodName);
          if (food) foodDetail(body, app, food, { source: 'suggestion', onBack: () => searchPane(body, app, ctx, done), done });
          else searchPane(body, app, ctx, done, opts.foodName);
        } else if (ctx.mode === 'search') searchPane(body, app, ctx, done, opts.query || '');
        else if (ctx.mode === 'barcode') barcodePane(body, app, ctx, done);
        else quickPane(body, app, ctx, done);
      };
      draw();
    },
    { full: true },
  );
}

// entries: [{ food, servings, thumb?, source }]
async function logEntries(app, ctx, entries) {
  if (!entries.length) return;
  const now = new Date();
  const time = ctx.date === app.today ? now.toISOString() : `${ctx.date}T12:00:00`;
  const ids = entries.map(() => uid());
  // All items from one photo share one thumbnail file.
  const thumbSrc = entries.find((e) => e.thumb)?.thumb;
  const thumb = thumbSrc ? await storeThumb(ids[0], thumbSrc) : null;
  app.update((s) => {
    for (const [i, e] of entries.entries()) {
      const k = e.servings;
      const f = e.food;
      s.meals.push({
        id: ids[i],
        date: ctx.date,
        time,
        mealType: ctx.mealType,
        name: f.name,
        servingText: `${trimNum(k)} × ${f.serving}`,
        servings: k,
        per: { calories: f.calories, protein: f.protein, carbs: f.carbs, fat: f.fat, serving: f.serving },
        calories: Math.round(f.calories * k),
        protein: round1(f.protein * k),
        carbs: round1(f.carbs * k),
        fat: round1(f.fat * k),
        foodId: f.id,
        loggedOn: app.today,
        source: e.source,
        thumb: e.thumb ? thumb : null,
        estimated: !!e.estimated,
      });
      // Remember recently-used foods for one-tap logging.
      s.recent = [{ ...f, aliases: undefined }, ...(s.recent || []).filter((r) => r.id !== f.id)].slice(0, 25);
    }
  });
  haptic('success');
  toast(entries.length === 1 ? `Logged ${entries[0].food.name}` : `Logged ${entries.length} items`, { icon: '✅' });
}

const round1 = (v) => Math.round(v * 10) / 10;
const trimNum = (v) => String(Math.round(v * 100) / 100);

function servingStepper(value) {
  return `<div class="stepper"><button data-step="-1" aria-label="Less">−</button><input data-serv type="number" inputmode="decimal" step="0.25" min="0.25" value="${trimNum(value)}"/><button data-step="1" aria-label="More">＋</button></div>`;
}

function bindStepper(root, onChange) {
  const input = root.querySelector('[data-serv]');
  const set = (v) => {
    const n = Math.max(0.25, Math.min(20, Math.round(v * 4) / 4));
    input.value = trimNum(n);
    onChange(n);
  };
  root.querySelectorAll('[data-step]').forEach(
    (b) =>
      (b.onclick = (e) => {
        e.stopPropagation();
        const cur = Number(input.value) || 1;
        set(cur + Number(b.dataset.step) * (cur < 1 || (cur === 1 && b.dataset.step === '-1') ? 0.25 : 0.5));
        haptic('light');
      }),
  );
  input.onchange = () => set(Number(input.value) || 1);
  input.onclick = (e) => e.stopPropagation();
}

// A single food → choose servings → log
function foodDetail(body, app, food, { source, thumb, estimated, onBack, done }) {
  let k = 1;
  const draw = () => {
    body.innerHTML = `
      <button class="link-btn" data-back>‹ Back</button>
      <div class="food-detail">
        ${thumb ? `<img class="detail-img" src="${esc(thumb)}" alt=""/>` : ''}
        <h3 class="food-title">${esc(food.name)}</h3>
        <div class="muted small">${esc(food.serving)} per serving${food.brand ? ` · ${esc(food.brand)}` : ''}${estimated ? ' · <span class="warn-text">rough estimate</span>' : ''}</div>
        <div class="detail-kcal"><b data-kcal>${fmt(food.calories * k)}</b><span>kcal</span></div>
        <div class="macro-grid sm">
          <div class="macro-card p"><b data-p>${fmt(food.protein * k, 0)}g</b><span>Protein</span></div>
          <div class="macro-card c"><b data-c>${fmt(food.carbs * k, 0)}g</b><span>Carbs</span></div>
          <div class="macro-card f"><b data-f>${fmt(food.fat * k, 0)}g</b><span>Fat</span></div>
        </div>
        <label class="label">Servings</label>
        ${servingStepper(k)}
        ${food.category === 'My foods' && (app.state.custom || []).some((c) => c.id === food.id) ? '<button class="link-btn danger" data-del-custom>Remove from my foods</button>' : ''}
        <div class="row gap mt">
          <button class="btn btn-ghost" data-fav>${(app.state.favorites || []).some((f) => f.id === food.id) ? '★ Saved' : '☆ Favorite'}</button>
          <button class="btn btn-primary grow" data-log>Log it · +10 XP</button>
        </div>
      </div>`;
    body.querySelector('[data-back]').onclick = onBack;
    bindStepper(body, (n) => {
      k = n;
      body.querySelector('[data-kcal]').textContent = fmt(food.calories * k);
      body.querySelector('[data-p]').textContent = `${fmt(food.protein * k)}g`;
      body.querySelector('[data-c]').textContent = `${fmt(food.carbs * k)}g`;
      body.querySelector('[data-f]').textContent = `${fmt(food.fat * k)}g`;
    });
    body.querySelector('[data-fav]').onclick = () => {
      app.update(
        (s) => {
          const has = s.favorites.some((f) => f.id === food.id);
          s.favorites = has ? s.favorites.filter((f) => f.id !== food.id) : [{ ...food, aliases: undefined }, ...s.favorites].slice(0, 50);
        },
        { render: false },
      );
      draw();
    };
    body.querySelector('[data-log]').onclick = () => done([{ food, servings: k, source, thumb, estimated }]);
    body.querySelector('[data-del-custom]')?.addEventListener('click', async () => {
      if (!(await confirmDialog({ title: 'Remove this food?', message: `${food.name} will be removed from your saved foods. Past log entries stay.`, confirm: 'Remove', danger: true }))) return;
      app.update((s) => {
        s.custom = (s.custom || []).filter((c) => c.id !== food.id);
        s.favorites = (s.favorites || []).filter((c) => c.id !== food.id);
        s.recent = (s.recent || []).filter((c) => c.id !== food.id);
      }, { render: false });
      onBack();
    });
  };
  draw();
}

// ---------- snap ----------

function snapPane(body, app, ctx, done) {
  body.innerHTML = `
    <div class="snap-hero">
      <div class="snap-icon">📸</div>
      <h3>Snap your plate</h3>
      <p class="muted small">On-device AI recognizes 2,000+ dishes. Nothing leaves your phone.</p>
      <div class="col gap">
        <button class="btn btn-primary btn-lg btn-block" data-cam>Take photo</button>
        <button class="btn btn-ghost btn-block" data-gal>Choose from gallery</button>
      </div>
      <p class="muted tiny mt">Tip: shoot from above in good light, one dish per photo works best.</p>
    </div>`;
  const run = async (source) => {
    let img;
    try {
      img = await pickImage(source);
    } catch (e) {
      if (e.message !== 'cancelled') toast(e.message || 'Could not open camera', { type: 'error' });
      return;
    }
    const canvas = toCanvas(img, 640);
    const thumb = thumbnail(canvas, 180, 0.6);
    body.innerHTML = `
      <div class="analyzing">
        <div class="scan-frame"><img src="${esc(thumb)}" alt=""/><div class="scan-line"></div></div>
        <b>Analyzing your food…</b>
        <span class="muted small" data-status>Loading AI model (first time takes a few seconds)</span>
      </div>`;
    try {
      const preds = await classifyFood(canvas, { imagenetFoods: IMAGENET_FOODS });
      showPredictions(body, app, ctx, preds, thumb, done, () => snapPane(body, app, ctx, done));
    } catch (e) {
      console.error(e);
      body.innerHTML = `<div class="empty"><div class="empty-icon">⚠️</div><b>AI model failed to load</b><p class="muted small">${esc(e.message || e)}</p><button class="btn btn-primary" data-retry>Try again</button> <button class="btn btn-ghost" data-search>Search instead</button></div>`;
      body.querySelector('[data-retry]').onclick = () => snapPane(body, app, ctx, done);
      body.querySelector('[data-search]').onclick = () => searchPane(body, app, ctx, done);
    }
  };
  body.querySelector('[data-cam]').onclick = () => run('camera');
  body.querySelector('[data-gal]').onclick = () => run('gallery');
}

function showPredictions(body, app, ctx, preds, thumb, done, retake) {
  // Merge predictions that map to the same database entry (their scores add up), keep top 6.
  const byFood = new Map();
  for (const pr of preds) {
    const m = foodForLabel(pr.label);
    if (!m) continue;
    const prev = byFood.get(m.food.id);
    if (!prev) byFood.set(m.food.id, { ...pr, ...m, servings: 1 });
    else if (!!prev.general !== !!pr.general) {
      // Both models agree on the food: combine like independent evidence.
      prev.score = 1 - (1 - prev.score) * (1 - pr.score);
      prev.general = 'both';
    } else prev.score = Math.max(prev.score, pr.score);
  }
  const items = [...byFood.values()].sort((a, b) => b.score - a.score).slice(0, 6);
  if (items[0] && items[0].score > 0.25) items[0].selected = true;
  const confident = items[0] && items[0].score >= 0.35;
  const draw = () => {
    const sel = items.filter((i) => i.selected);
    const kcal = sel.reduce((s, i) => s + i.food.calories * i.servings, 0);
    body.innerHTML = `
      <div class="pred-head">
        <img class="pred-img" src="${esc(thumb)}" alt=""/>
        <div class="grow">
          <b>${items.length ? (confident ? 'Looks like…' : 'Best guesses') : 'Hmm, not sure what that is'}</b>
          <p class="muted tiny">${items.length ? 'Tap everything on your plate, then adjust servings.' : 'Try another angle or search instead.'}</p>
        </div>
      </div>
      <div class="pred-list">
        ${items
          .map(
            (it, idx) => `
          <div class="pred ${it.selected ? 'selected' : ''}" data-idx="${idx}" role="checkbox" tabindex="0" aria-checked="${it.selected}">
            <div class="check">${it.selected ? '✓' : ''}</div>
            <div class="grow">
              <div class="pred-name">${esc(it.label)}</div>
              <div class="muted tiny">${it.estimated ? '≈ ' : ''}${fmt(it.food.calories)} kcal · ${esc(it.food.serving)}${it.exact || it.estimated ? '' : ` · as “${esc(it.food.name)}”`}</div>
              <div class="conf"><div style="width:${Math.round(it.score * 100)}%"></div></div>
            </div>
            ${it.selected ? servingStepper(it.servings) : `<span class="conf-num">${Math.round(it.score * 100)}%</span>`}
          </div>`,
          )
          .join('')}
      </div>
      <div class="row gap">
        <button class="btn btn-ghost grow" data-other>Something else</button>
        <button class="btn btn-ghost" data-retake>Retake</button>
      </div>
      <button class="btn btn-primary btn-block btn-lg mt" data-log ${sel.length ? '' : 'disabled'}>${sel.length ? `Log ${sel.length} item${sel.length > 1 ? 's' : ''} · ${fmt(kcal)} kcal` : 'Select what you ate'}</button>`;
    body.querySelectorAll('.pred').forEach((row) => {
      const it = items[Number(row.dataset.idx)];
      row.onclick = () => {
        it.selected = !it.selected;
        haptic('light');
        draw();
      };
      if (it.selected) bindStepper(row, (n) => {
        it.servings = n;
        const s2 = items.filter((i) => i.selected);
        body.querySelector('[data-log]').textContent = `Log ${s2.length} item${s2.length > 1 ? 's' : ''} · ${fmt(s2.reduce((s, i) => s + i.food.calories * i.servings, 0))} kcal`;
      });
    });
    body.querySelector('[data-other]').onclick = () => searchPane(body, app, ctx, (entries) => done(entries.map((e) => ({ ...e, thumb: e.thumb || thumb, source: 'photo' }))));
    body.querySelector('[data-retake]').onclick = retake;
    body.querySelector('[data-log]').onclick = () => {
      const chosen = items.filter((i) => i.selected).map((i) => ({ food: { ...i.food, name: i.estimated || i.exact ? i.food.name : i.food.name }, servings: i.servings, thumb, source: 'photo', estimated: i.estimated }));
      if (chosen.length) done(chosen);
    };
  };
  draw();
}

// ---------- search ----------

function searchPane(body, app, ctx, done, initial = '') {
  const state = app.state;
  let query = initial;
  let online = [];
  let onlineState = 'idle';
  const draw = () => {
    const all = [...(state.custom || []), ...FOODS];
    const local = query ? searchFoods(query, all) : [];
    body.innerHTML = `
      <div class="search-box"><input class="input" data-q type="search" placeholder="Search foods, e.g. chicken burrito" value="${esc(query)}" autocomplete="off"/></div>
      <div class="search-results">
        ${
          query
            ? `${local.map((f) => foodRow(f)).join('') || '<p class="muted small pad">No matches in the built-in database.</p>'}
               <div class="online-block">
                 ${
                   onlineState === 'loading'
                     ? '<p class="muted small pad">Searching Open Food Facts…</p>'
                     : onlineState === 'done'
                       ? online.length
                         ? `<div class="list-label">Packaged foods · Open Food Facts</div>${online.map((f, i) => foodRow(f, `o${i}`)).join('')}`
                         : '<p class="muted small pad">No packaged products found.</p>'
                       : onlineState === 'error'
                         ? '<p class="muted small pad">Couldn’t reach Open Food Facts (offline?).</p>'
                         : `<button class="btn btn-ghost btn-block" data-online>🌐 Search packaged foods online</button>`
                 }
               </div>
               <button class="btn btn-ghost btn-block mt" data-quick>✏️ Add “${esc(query)}” manually</button>`
            : `${listSection('★ Favorites', state.favorites || [])}${listSection('🕘 Recent', state.recent || [])}${listSection('✏️ My foods', state.custom || [])}
               ${FOOD_CATEGORIES.map((c) => `<details class="cat"><summary>${esc(c)}</summary>${FOODS.filter((f) => f.category === c).map((f) => foodRow(f)).join('')}</details>`).join('')}`
        }
      </div>`;
    const input = body.querySelector('[data-q]');
    input.oninput = debounce(() => {
      query = input.value.trim();
      onlineState = 'idle';
      online = [];
      const pos = input.selectionStart;
      draw();
      const ni = body.querySelector('[data-q]');
      ni.focus();
      ni.setSelectionRange(pos, pos);
    }, 180);
    body.querySelector('[data-online]')?.addEventListener('click', async () => {
      const asked = query;
      onlineState = 'loading';
      draw();
      let results = [];
      let state2 = 'done';
      try {
        results = await searchOnline(asked);
      } catch {
        state2 = 'error';
      }
      if (asked !== query || !body.isConnected) return; // the user typed something else meanwhile
      online = results;
      onlineState = state2;
      draw();
    });
    body.querySelector('[data-quick]')?.addEventListener('click', () => quickPane(body, app, ctx, done, query));
    body.querySelectorAll('[data-food]').forEach((row) => {
      row.onclick = () => {
        const id = row.dataset.food;
        const food = id.startsWith('o') && row.dataset.online ? online[Number(id.slice(1))] : findFood(state, id);
        if (!food) return;
        foodDetail(body, app, food, { source: row.dataset.online ? 'online' : 'search', onBack: draw, done });
      };
    });
    if (!initial || query) setTimeout(() => body.querySelector('[data-q]')?.focus(), 50);
  };
  draw();
}

function findFood(state, id) {
  return [...(state.custom || []), ...(state.favorites || []), ...(state.recent || []), ...FOODS].find((f) => f.id === id);
}

function listSection(title, list) {
  if (!list.length) return '';
  return `<div class="list-label">${title}</div>${list.slice(0, 12).map((f) => foodRow(f)).join('')}`;
}

function foodRow(f, onlineId) {
  return `
    <button class="food-row" data-food="${esc(onlineId || f.id)}" ${onlineId ? 'data-online="1"' : ''}>
      ${f.image ? `<img class="food-img" src="${esc(f.image)}" alt="" loading="lazy"/>` : ''}
      <div class="grow left">
        <div class="food-name">${esc(f.name)}</div>
        <div class="muted tiny">${f.brand ? `${esc(f.brand)} · ` : ''}${esc(f.serving)} · P ${fmt(f.protein)} C ${fmt(f.carbs)} F ${fmt(f.fat)}</div>
      </div>
      <b class="food-kcal">${fmt(f.calories)}</b>
    </button>`;
}

// ---------- barcode ----------

function barcodePane(body, app, ctx, done) {
  body.innerHTML = `
    <div class="snap-hero">
      <div class="snap-icon">▥</div>
      <h3>Scan a barcode</h3>
      <p class="muted small">Looks up nutrition from the free Open Food Facts database (3M+ products).</p>
      <button class="btn btn-primary btn-lg btn-block" data-scan>${isNative() ? 'Open scanner' : 'Scan (phone only)'}</button>
      <div class="or">or type it</div>
      <div class="row gap"><input class="input grow" data-code inputmode="numeric" placeholder="e.g. 0049000028911"/><button class="btn btn-ghost" data-go>Look up</button></div>
      <div data-msg class="muted small mt"></div>
    </div>`;
  const msg = body.querySelector('[data-msg]');
  const look = async (code) => {
    msg.textContent = 'Looking up product…';
    try {
      const food = await lookupBarcode(code);
      if (!food) {
        msg.innerHTML = 'Product not found. <button class="link-btn" data-manual>Add it manually</button>';
        msg.querySelector('[data-manual]').onclick = () => quickPane(body, app, ctx, done);
        return;
      }
      foodDetail(body, app, food, { source: 'barcode', onBack: () => barcodePane(body, app, ctx, done), done });
    } catch {
      msg.textContent = 'Couldn’t reach Open Food Facts. Check your connection.';
    }
  };
  body.querySelector('[data-scan]').onclick = async () => {
    try {
      const code = await scanBarcode();
      if (code) {
        body.querySelector('[data-code]').value = code;
        look(code);
      }
    } catch (e) {
      msg.textContent = e.message || 'Scanner unavailable — type the number instead.';
    }
  };
  body.querySelector('[data-go]').onclick = () => {
    const code = body.querySelector('[data-code]').value.replace(/\D/g, '');
    if (code.length < 6) {
      msg.textContent = 'Enter the full barcode number.';
      return;
    }
    look(code);
  };
}

// ---------- quick add ----------

function quickPane(body, app, ctx, done, name = '') {
  body.innerHTML = `
    <div class="form">
      <label class="label">Name</label>
      <input class="input" data-n placeholder="e.g. Mom’s lasagna" value="${esc(name)}"/>
      <label class="label">Calories</label>
      <input class="input input-xl" data-kcal type="number" inputmode="numeric" placeholder="kcal"/>
      <div class="grid3">
        <div><label class="label">Protein g</label><input class="input" data-p type="number" inputmode="decimal" placeholder="0"/></div>
        <div><label class="label">Carbs g</label><input class="input" data-c type="number" inputmode="decimal" placeholder="0"/></div>
        <div><label class="label">Fat g</label><input class="input" data-f type="number" inputmode="decimal" placeholder="0"/></div>
      </div>
      <label class="check-row"><input type="checkbox" data-save/> Save to my foods</label>
      <div class="onb-error" data-err></div>
      <button class="btn btn-primary btn-block btn-lg" data-log>Log it · +10 XP</button>
    </div>`;
  const v = (s) => Number(body.querySelector(s).value) || 0;
  body.querySelector('[data-log]').onclick = () => {
    const n = body.querySelector('[data-n]').value.trim() || 'Quick add';
    let kcal = v('[data-kcal]');
    const p = v('[data-p]');
    const c = v('[data-c]');
    const f = v('[data-f]');
    if (p < 0 || c < 0 || f < 0 || kcal < 0) {
      body.querySelector('[data-err]').textContent = 'Values can’t be negative.';
      return;
    }
    if (!kcal && (p || c || f)) kcal = Math.round(p * 4 + c * 4 + f * 9);
    if (!kcal || kcal > 10000 || p > 1000 || c > 2000 || f > 1000) {
      body.querySelector('[data-err]').textContent = 'Enter calories (or macros) between 1 and 10,000.';
      return;
    }
    const food = { id: `c${uid()}`, name: n.slice(0, 60), serving: '1 serving', calories: Math.round(kcal), protein: p, carbs: c, fat: f, category: 'My foods', aliases: [] };
    if (body.querySelector('[data-save]').checked) app.update((s) => (s.custom = [food, ...(s.custom || [])].slice(0, 200)), { render: false });
    done([{ food, servings: 1, source: 'quick' }]);
  };
  setTimeout(() => body.querySelector(name ? '[data-kcal]' : '[data-n]')?.focus(), 60);
}

// ---------- edit ----------

function editMeal(app, id) {
  const m = app.state.meals.find((x) => x.id === id);
  if (!m) return;
  const per = m.per || { calories: m.calories, protein: m.protein, carbs: m.carbs, fat: m.fat, serving: 'serving' };
  let k = m.servings || 1;
  let type = m.mealType || 'snack';
  sheet((el, close) => {
    el.innerHTML = `
      <div class="food-detail">
        ${m.thumb ? `<img class="detail-img" src="${esc(m.thumb)}" alt=""/>` : ''}
        <h3 class="food-title">${esc(m.name)}</h3>
        <div class="muted small">${esc(per.serving)} per serving${m.estimated ? ' · <span class="warn-text">rough estimate</span>' : ''}</div>
        <div class="detail-kcal"><b data-kcal>${fmt(per.calories * k)}</b><span>kcal</span></div>
        <label class="label">Servings</label>
        ${servingStepper(k)}
        <label class="label">Meal</label>
        <div class="seg seg-4">${MEAL_TYPES.map((t) => `<button class="seg-btn ${t.id === type ? 'active' : ''}" data-mt="${t.id}">${t.icon}</button>`).join('')}</div>
        <div class="row gap mt">
          <button class="btn btn-danger" data-del>Delete</button>
          <button class="btn btn-primary grow" data-save>Save</button>
        </div>
      </div>`;
    bindStepper(el, (n) => {
      k = n;
      el.querySelector('[data-kcal]').textContent = fmt(per.calories * k);
    });
    el.querySelectorAll('[data-mt]').forEach(
      (b) =>
        (b.onclick = () => {
          type = b.dataset.mt;
          el.querySelectorAll('[data-mt]').forEach((x) => x.classList.toggle('active', x === b));
        }),
    );
    el.querySelector('[data-save]').onclick = () => {
      app.update((s) => {
        const x = s.meals.find((y) => y.id === id);
        Object.assign(x, {
          servings: k,
          mealType: type,
          servingText: `${trimNum(k)} × ${per.serving}`,
          calories: Math.round(per.calories * k),
          protein: round1(per.protein * k),
          carbs: round1(per.carbs * k),
          fat: round1(per.fat * k),
        });
      });
      close();
    };
    el.querySelector('[data-del]').onclick = async () => {
      if (!(await confirmDialog({ title: 'Delete this entry?', message: `${m.name} will be removed from your log.`, confirm: 'Delete', danger: true }))) return;
      app.update((s) => (s.meals = s.meals.filter((y) => y.id !== id)));
      // Only remove the photo file once no other entry from the same photo uses it.
      if (m.thumb && !app.state.meals.some((y) => y.thumb === m.thumb)) deleteThumb(m.id, m.thumb);
      close();
    };
  });
}
