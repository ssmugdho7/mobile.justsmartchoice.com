#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Full Xcode is required. Select Xcode in Settings > Locations before building iOS." >&2
  exit 1
fi
sdk_version=$(xcrun --sdk iphoneos --show-sdk-version)
if (( ${sdk_version%%.*} < 26 )); then
  echo "App Store submissions currently require an iOS 26 or later SDK. Selected: $sdk_version" >&2
  exit 1
fi
xcodebuild -version
printf 'iPhoneOS SDK: %s\n' "$sdk_version"
./tool/check-ios-source.sh
# Compilation only. This produces no signed archive or installable IPA.
"$FLUTTER_BIN" build ios --release --no-codesign
