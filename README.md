# GrindFit 🛡️⚡

An AI calorie tracker and body-fat scanner, built as a ranked grinding game for Android.

Snap your meals, scan your body and finish daily challenges to earn XP and rank up from **Iron** to **Legend**.

- **No API keys. No subscription. No account.** All the AI runs on your phone.
- **Private.** Your photos and data never leave the device.

## Download

**[⬇ GrindFit.apk](releases/GrindFit.apk)**

To install it:
1. Open the link on your Android phone and tap **Download**.
2. Open the file. If Android asks, allow **Install unknown apps** for your browser.
3. Tap **Install**.

It needs Android 7.0 or newer. Later versions install over the top and keep your data.

## Features

| | |
|---|---|
| 📸 **Snap meals** | On-device AI recognises 2,000+ dishes. Tick what's on your plate, adjust the servings, log it. |
| 🔎 **Search & quick add** | Built-in database of ~250 common foods, plus favourites, recents and your own custom foods. |
| ▥ **Barcode scanner** | Google ML Kit scanner with free Open Food Facts lookups (3M+ products). |
| 🧬 **AI body-fat scan** | A live camera guide checks your pose and counts down. The AI outlines your body and measures your waist, then estimates body fat with the Relative Fat Mass formula. A side photo makes it more accurate. |
| 📏 **Tape scan** | RFM averaged with the U.S. Navy formula. Doing one on the same day as a photo scan calibrates your future photo scans. |
| ⚔️ **Daily challenges** | Workouts, nutrition and lifestyle challenges that scale with your rank. One swap per day, and a 2× XP boss challenge every Sunday. |
| ✅ **Daily quests** | Log 3 meals, hit your protein, land your calories in range. All auto-tracked. |
| 🔥 **Streaks** | Up to a ×1.5 XP multiplier. Every 7-day run earns a freeze that protects your streak if you miss a day. |
| 🏆 **Ranks & leagues** | 9 ranks with 3 divisions each. In the weekly league, the top 3 get promoted and the bottom 3 get demoted. |
| 🎖️ **Badges** | 21 achievements. |
| 📈 **Progress** | Body-fat trend with confidence bands, weight, calories, XP and side-by-side progress photos. |
| 🔔 **Reminders** | An evening alert when your streak is at risk, and a morning ping for the new challenge. |

## How the AI works (all offline)

**Food recognition.** Google's AIY food classifier (`food_V1`, 2,023 classes) runs through MediaPipe Tasks in the app's WebView. Each dish label is matched to the nutrition database by phrase and main noun ("Chicken **curry**" → curry). Unknown dishes fall back to an estimate for their dish type, marked "≈".

**Body fat.** The MediaPipe Pose Landmarker (full model, with segmentation masks) finds 33 body landmarks and a body outline. Steps:
1. Your height is the ruler: pixels are converted to centimetres.
2. It measures waist width at the iliac crest, and depth too if you add a side photo.
3. It treats the waist as an ellipse to get the circumference.
4. It applies **RFM = 64 − 20 × height/waist** (men) or **76 − 20 × height/waist** (women), from Woolcott & Bergman 2018, which was validated against DEXA.

Expect about ±3–5%. Keep the same setup every time and watch the trend.

**Targets.** Mifflin-St Jeor × activity level, then −20% for a cut or +10% for a bulk. Protein is 1.8–2.2 g per kg of body weight.

## XP table

| Action | XP |
|---|---|
| Log a meal (max 6 a day) | +10 |
| Log 3+ meals | +20 |
| Hit protein goal | +40 |
| Calories on target | +40 |
| Daily challenge | +50 / 80 / 120 (×2 on Sunday) |
| Body scan (1 a day) | +50 |
| New body-fat low (vs earlier days) | +100 per % (max 300) |
| Streak multiplier | +5% per day, up to ×1.5 |

## Build it yourself

```bash
npm install
npm run models        # downloads the two free ML models (~30 MB)
npm test              # unit tests for the game engine, body-fat maths and food mapping
npm run build         # bundles the app into www/
npm run serve         # optional: try it in a desktop browser at localhost:8080

# Android (needs JDK 21 + Android SDK 36)
npx cap sync android
cd android && ./gradlew assembleRelease
# → android/app/build/outputs/apk/release/app-release.apk
```

Release signing reads `android/keystore.properties` (git-ignored: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Without it, the build signs with your local debug key. Keep the key safe: Android only installs updates signed with the same key.

## Project layout

```
src/lib/       game engine (XP, ranks, streaks, leagues, challenges), body-fat maths, food DB — pure & tested
src/ml/        MediaPipe wrappers, camera/gallery input, body-scan pipeline
src/ui/        screens: onboarding, home, food, scan, ranks, me, live camera
test/          node:test unit tests
scripts/       build, model download, icon rendering
android/       Capacitor Android project
```

## Disclaimer

GrindFit is not a medical device and doesn't give medical advice. Body-fat scans are only available to users aged 18 and over. If you have a history of disordered eating, talk to a professional before tracking calories.
