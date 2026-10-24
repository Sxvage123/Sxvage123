// On-device ML (MediaPipe Tasks, runs in the WebView — no network, no API keys).
// Models ship inside the APK under /models; the WASM runtime under /mediapipe.

import { FilesetResolver, ImageClassifier, PoseLandmarker } from '@mediapipe/tasks-vision';

const WASM_PATH = new URL('mediapipe', document.baseURI).href.replace(/\/$/, '');
const MODELS = {
  food: 'models/food_V1.tflite',
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
}

// Returns [{ label, score }] best first. The food model has ~2000 dish classes.
export async function classifyFood(image) {
  const model = await loadFoodModel();
  const result = model.classify(image);
  const cats = result.classifications?.[0]?.categories || [];
  return cats
    .map((c) => ({ label: (c.displayName || c.categoryName || '').trim(), score: c.score }))
    .filter((c) => c.label && c.label !== '__background__' && !c.label.startsWith('/'));
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
