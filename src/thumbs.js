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
    await Filesystem.deleteFile({ path: `${DIR}/${id}.jpg`, directory: Directory.Data });
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
