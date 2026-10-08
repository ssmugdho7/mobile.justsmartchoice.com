#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
"$FLUTTER_BIN" build apk --debug "$@"
mkdir -p dist
cp build/app/outputs/flutter-apk/app-debug.apk dist/smart-choice-mobile-debug.apk
echo "APK: $(pwd)/dist/smart-choice-mobile-debug.apk"
