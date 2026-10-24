// Photo thumbnails live in their own files (not inside the big state blob), so saving
// the app state stays fast even after a year of meal photos. Web builds keep data URLs.

import { Capacitor } from '@capacitor/core';
import { Filesystem, Directory } from '@capacitor/filesystem';

const DIR = 'thumbs';

export async function storeThumb(id, dataUrl) {
  if (!dataUrl || !Capacitor.isNativePlatform() || !dataUrl.startsWith('data:image/')) return dataUrl || null;
  try {
    const { uri } = await Filesystem.writeFile({
      path: `${DIR}/${id}.jpg`,
      data: dataUrl.split(',')[1],
      directory: Directory.Data,
      recursive: true,
    });
    return Capacitor.convertFileSrc(uri);
  } catch (e) {
    console.warn('thumb write failed; keeping inline', e);
    return dataUrl;
  }
}

export async function deleteThumb(id, thumb) {
  if (!thumb || thumb.startsWith('data:') || !Capacitor.isNativePlatform()) return;
  try {
    await Filesystem.deleteFile({ path: `${DIR}/${fileIdOf(thumb) || id}.jpg`, directory: Directory.Data });
  } catch {
    /* already gone */
  }
}

// One-time move of inline thumbnails (older versions) into files.
export async function migrateInlineThumbs(state) {
  if (!Capacitor.isNativePlatform()) return false;
  let changed = false;
  for (const list of [state.meals, state.scans]) {
    for (const item of list) {
      if (item.thumb && item.thumb.startsWith('data:image/')) {
        const url = await storeThumb(item.id, item.thumb);
        if (url !== item.thumb) {
          item.thumb = url;
          changed = true;
        }
      }
    }
  }
  return changed;
}

const fileIdOf = (thumb) => thumb && thumb.match(/thumbs\/([\w-]+)\.jpg/)?.[1];

// Backups must be portable: turn file thumbnails back into data URLs.
export async function inlineThumbs(state) {
  const copy = JSON.parse(JSON.stringify(state));
  if (!Capacitor.isNativePlatform()) return copy;
  for (const list of [copy.meals, copy.scans]) {
    for (const item of list) {
      const id = fileIdOf(item.thumb);
      if (!id) continue;
      try {
        const { data } = await Filesystem.readFile({ path: `${DIR}/${id}.jpg`, directory: Directory.Data });
        item.thumb = `data:image/jpeg;base64,${data}`;
      } catch {
        item.thumb = null;
      }
    }
  }
  return copy;
}

// Deletes thumbnail files nothing references anymore (after a reset or restore).
export async function cleanupThumbs(state) {
  if (!Capacitor.isNativePlatform()) return;
  const used = new Set([...state.meals, ...state.scans].map((x) => fileIdOf(x.thumb)).filter(Boolean));
  try {
    const { files } = await Filesystem.readdir({ path: DIR, directory: Directory.Data });
    for (const f of files) {
      const name = typeof f === 'string' ? f : f.name;
      const id = name.replace(/\.jpg$/, '');
      if (!used.has(id)) await Filesystem.deleteFile({ path: `${DIR}/${name}`, directory: Directory.Data }).catch(() => {});
    }
  } catch {
    /* no thumbs dir yet */
  }
}
