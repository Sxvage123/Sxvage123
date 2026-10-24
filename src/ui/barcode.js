// Barcode scanning (Google ML Kit, on-device) + Open Food Facts lookups (free, no key).

import { Capacitor } from '@capacitor/core';
import { BarcodeScanner, BarcodeFormat } from '@capacitor-mlkit/barcode-scanning';

const OFF = 'https://world.openfoodfacts.org';
const FIELDS = 'code,product_name,generic_name,brands,nutriments,serving_size,serving_quantity,image_front_small_url';

const num = (v) => (typeof v === 'number' && isFinite(v) ? v : Number(v) || 0);
const r1 = (v) => Math.round(v * 10) / 10;

// Converts an Open Food Facts product into our food shape (per serving when known, else per 100 g).
export function offToFood(p) {
  if (!p) return null;
  const n = p.nutriments || {};
  const name = (p.product_name || p.generic_name || '').trim();
  const kcal100 = num(n['energy-kcal_100g']) || num(n['energy_100g']) / 4.184;
  if (!name || !kcal100) return null;
  const servingG = num(p.serving_quantity);
  const hasServing = servingG > 0 && servingG < 2000;
  const f = hasServing ? servingG / 100 : 1;
  const perServing = (key) => {
    const s = num(n[`${key}_serving`]);
    return hasServing && s ? s : num(n[`${key}_100g`]) * f;
  };
  const kcalServing = hasServing && num(n['energy-kcal_serving']) ? num(n['energy-kcal_serving']) : kcal100 * f;
  return {
    id: `off:${p.code}`,
    name,
    brand: (p.brands || '').split(',')[0].trim(),
    serving: hasServing ? p.serving_size || `${servingG} g` : '100 g',
    calories: Math.round(kcalServing),
    protein: r1(perServing('proteins')),
    carbs: r1(perServing('carbohydrates')),
    fat: r1(perServing('fat')),
    image: p.image_front_small_url || '',
    category: 'Packaged',
    aliases: [],
  };
}

async function getJSON(url, timeout = 9000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeout);
  try {
    const res = await fetch(url, { signal: ctrl.signal, headers: { Accept: 'application/json' } });
    if (!res.ok && res.status !== 404) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } finally {
    clearTimeout(t);
  }
}

export async function lookupBarcode(code) {
  const data = await getJSON(`${OFF}/api/v2/product/${encodeURIComponent(code)}.json?fields=${FIELDS}`);
  if (!data || data.status !== 1) return null;
  return offToFood({ ...data.product, code });
}

export async function searchOnline(query) {
  const url = `${OFF}/cgi/search.pl?search_terms=${encodeURIComponent(query)}&search_simple=1&action=process&json=1&page_size=20&fields=${FIELDS}`;
  const data = await getJSON(url, 12000);
  return (data.products || []).map(offToFood).filter(Boolean).slice(0, 15);
}

const FORMATS = [BarcodeFormat.Ean13, BarcodeFormat.Ean8, BarcodeFormat.UpcA, BarcodeFormat.UpcE, BarcodeFormat.Code128];

export async function scanBarcode() {
  if (!Capacitor.isNativePlatform()) throw new Error('Live scanning works in the Android app. Type the number below instead.');
  const { supported } = await BarcodeScanner.isSupported();
  if (!supported) throw new Error('This phone does not support barcode scanning. Type the number instead.');
  const { available } = await BarcodeScanner.isGoogleBarcodeScannerModuleAvailable();
  if (!available) {
    await BarcodeScanner.installGoogleBarcodeScannerModule();
    throw new Error('Installing Google’s barcode scanner (one-time download). Try again in a few seconds.');
  }
  try {
    const { barcodes } = await BarcodeScanner.scan({ formats: FORMATS, autoZoom: true });
    return barcodes?.[0]?.rawValue || barcodes?.[0]?.displayValue || null;
  } catch (e) {
    if (String(e?.message || e).toLowerCase().includes('cancel')) return null;
    throw e;
  }
}
