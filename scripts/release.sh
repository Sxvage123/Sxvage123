#!/usr/bin/env bash
# Builds a signed release APK into releases/GrindFit.apk.
# Usage: scripts/release.sh <versionName>   (versionCode auto-increments)
set -euo pipefail
cd "$(dirname "$0")/.."
export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
VERSION="${1:?versionName required, e.g. 1.1.0}"
# Verify first, so a failing check never leaves a half-bumped version behind.
npm run lint
npm test
GRADLE=android/app/build.gradle
CODE=$(( $(grep -oP 'versionCode \K\d+' "$GRADLE") + 1 ))
sed -i -E "s/versionCode [0-9]+/versionCode $CODE/; s/versionName \"[^\"]+\"/versionName \"$VERSION\"/" "$GRADLE"
sed -i -E "s/const APP_VERSION = '[^']+'/const APP_VERSION = '$VERSION'/" src/version.js
npm run build
npx cap sync android
(cd android && ./gradlew assembleRelease --no-daemon --console=plain -q)
mkdir -p releases
cp android/app/build/outputs/apk/release/app-release.apk releases/GrindFit.apk
ls -la releases/GrindFit.apk
echo "Built GrindFit $VERSION ($CODE)"
