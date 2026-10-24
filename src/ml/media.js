// Getting images in: native camera/gallery on Android, file input on the web.

import { Capacitor } from '@capacitor/core';
import { Camera } from '@capacitor/camera';

export const isNative = () => Capacitor.isNativePlatform();

export function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.decoding = 'async';
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('Could not read that image.'));
    img.src = src;
  });
}

// Downscale to keep ML fast and storage small. Returns a canvas.
export function toCanvas(img, maxSide = 1280) {
  const scale = Math.min(1, maxSide / Math.max(img.naturalWidth || img.width, img.naturalHeight || img.height));
  const w = Math.round((img.naturalWidth || img.width) * scale);
  const h = Math.round((img.naturalHeight || img.height) * scale);
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  c.getContext('2d').drawImage(img, 0, 0, w, h);
  return c;
}

export function thumbnail(source, maxSide = 220, quality = 0.62) {
  const w0 = source.naturalWidth || source.videoWidth || source.width;
  const h0 = source.naturalHeight || source.videoHeight || source.height;
  const scale = Math.min(1, maxSide / Math.max(w0, h0));
  const c = document.createElement('canvas');
  c.width = Math.round(w0 * scale);
  c.height = Math.round(h0 * scale);
  c.getContext('2d').drawImage(source, 0, 0, c.width, c.height);
  return c.toDataURL('image/jpeg', quality);
}

function pickFile(capture) {
  return new Promise((resolve, reject) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    if (capture) input.capture = capture;
    input.style.display = 'none';
    document.body.appendChild(input);
    let settled = false;
    input.onchange = () => {
      settled = true;
      const file = input.files?.[0];
      input.remove();
      if (!file) return reject(new Error('cancelled'));
      resolve(URL.createObjectURL(file));
    };
    // If the picker is dismissed we never get a change event; clean up on next focus.
    window.addEventListener(
      'focus',
      () =>
        setTimeout(() => {
          if (!settled) {
            input.remove();
            reject(new Error('cancelled'));
          }
        }, 1500),
      { once: true },
    );
    input.click();
  });
}

// source: 'camera' | 'gallery'. Resolves to an HTMLImageElement, rejects with 'cancelled'.
export async function pickImage(source = 'camera') {
  let src;
  if (isNative()) {
    try {
      if (source === 'camera') {
        const r = await Camera.takePhoto({ quality: 85, targetWidth: 1600, targetHeight: 1600, correctOrientation: true });
        src = r.webPath || (r.uri && Capacitor.convertFileSrc(r.uri));
      } else {
        const r = await Camera.chooseFromGallery({ mediaType: 'photo', allowMultipleSelection: false, limit: 1 });
        const m = r.results?.[0];
        src = m && (m.webPath || (m.uri && Capacitor.convertFileSrc(m.uri)));
      }
    } catch (e) {
      const msg = String(e?.message || e).toLowerCase();
      if (msg.includes('cancel')) throw new Error('cancelled');
      throw e;
    }
    if (!src) throw new Error('cancelled');
  } else {
    src = await pickFile(source === 'camera' ? 'environment' : undefined);
  }
  return loadImage(src);
}
