// On-device ML (MediaPipe Tasks, runs in the WebView — no network, no API keys).
// Models ship inside the APK under /models; the WASM runtime under /mediapipe.

import { FilesetResolver, ImageClassifier, PoseLandmarker } from '@mediapipe/tasks-vision';

const WASM_PATH = new URL('mediapipe', document.baseURI).href.replace(/\/$/, '');
const MODELS = {
  food: 'models/food_V1.tflite',
  general: 'models/efficientnet_lite0.tflite',
  pose: 'models/pose_landmarker_full.task',
};

let filesetPromise;
const fileset = () => (filesetPromise ||= FilesetResolver.forVisionTasks(WASM_PATH));

// Try GPU first (much faster), fall back to CPU if WebGL isn't available.
// The food classifier is a quantized (uint8) model, which only runs on the CPU delegate.
async function create(factory, options, { gpu = true } = {}) {
  const fs = await fileset();
  if (!gpu) return factory.createFromOptions(fs, { ...options, baseOptions: { ...options.baseOptions, delegate: 'CPU' } });
  try {
    return await factory.createFromOptions(fs, { ...options, baseOptions: { ...options.baseOptions, delegate: 'GPU' } });
  } catch (e) {
    console.warn('GPU delegate failed, using CPU', e);
    return factory.createFromOptions(fs, { ...options, baseOptions: { ...options.baseOptions, delegate: 'CPU' } });
  }
}

let foodPromise;
export function loadFoodModel() {
  return (foodPromise ||= create(ImageClassifier, {
    baseOptions: { modelAssetPath: MODELS.food },
    runningMode: 'IMAGE',
    maxResults: 8,
  }, { gpu: false }).catch((e) => {
    foodPromise = null;
    throw e;
  }));
}

// General-purpose ImageNet classifier: much better at single ingredients (banana, broccoli…).
let generalPromise;
export function loadGeneralModel() {
  return (generalPromise ||= create(ImageClassifier, {
    baseOptions: { modelAssetPath: MODELS.general },
    runningMode: 'IMAGE',
    maxResults: 10,
  }, { gpu: false }).catch((e) => {
    generalPromise = null;
    throw e;
  }));
}

let posePromise;
let videoPosePromise;
export function loadPoseModel() {
  return (posePromise ||= create(PoseLandmarker, {
    baseOptions: { modelAssetPath: MODELS.pose },
    runningMode: 'IMAGE',
    numPoses: 1,
    outputSegmentationMasks: true,
  }).catch((e) => {
    posePromise = null;
    throw e;
  }));
}

// A second, lightweight instance for the live camera guide (no masks, video mode).
export function loadVideoPoseModel() {
  return (videoPosePromise ||= create(PoseLandmarker, {
    baseOptions: { modelAssetPath: MODELS.pose },
    runningMode: 'VIDEO',
    numPoses: 1,
    outputSegmentationMasks: false,
  }).catch((e) => {
    videoPosePromise = null;
    throw e;
  }));
}

export function preloadModels() {
  // Warm up in the background after first paint so the first scan feels instant.
  loadFoodModel().catch(() => {});
  loadGeneralModel().catch(() => {});
}

const categories = (result) =>
  (result.classifications?.[0]?.categories || []).map((c) => ({ label: (c.displayName || c.categoryName || '').trim(), score: c.score }));

// Returns [{ label, score }] best first, merging the dish model (~2,000 dishes) with the
// general model's food classes (mapped to database names).
export async function classifyFood(image, { imagenetFoods = {} } = {}) {
  const [dish, general] = await Promise.all([loadFoodModel(), loadGeneralModel().catch(() => null)]);
  const out = categories(dish.classify(image)).filter((c) => c.label && c.label !== '__background__' && !c.label.startsWith('/'));
  if (general) {
    for (const c of categories(general.classify(image))) {
      const name = imagenetFoods[c.label];
      if (name && c.score >= 0.12) out.push({ label: name, score: c.score, general: true });
    }
  }
  return out.sort((a, b) => b.score - a.score);
}

// Runs pose + segmentation on a still image and returns plain data (mask copied out of GPU memory).
export async function detectBody(image) {
  const model = await loadPoseModel();
  const result = model.detect(image);
  const landmarks = result.landmarks?.[0] || null;
  const maskObj = result.segmentationMasks?.[0];
  let mask = null;
  let width = 0;
  let height = 0;
  if (maskObj) {
    mask = maskObj.getAsFloat32Array().slice();
    width = maskObj.width;
    height = maskObj.height;
    maskObj.close();
  }
  return { landmarks, mask, width, height };
}

let lastVideoTs = 0;
export function detectBodyVideo(model, video) {
  const ts = Math.max(performance.now(), lastVideoTs + 1);
  lastVideoTs = ts;
  const result = model.detectForVideo(video, ts);
  return result.landmarks?.[0] || null;
}
