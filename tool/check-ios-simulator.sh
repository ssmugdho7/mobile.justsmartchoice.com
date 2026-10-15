#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
xcodebuild -version >/dev/null
selection=$(mktemp "${TMPDIR:-/tmp}/smart-choice-simulator.XXXXXX")
xcrun simctl list -j > "$selection"
simulator=''
cleanup() {
  code=$?
  if [ -n "$simulator" ]; then
    xcrun simctl shutdown "$simulator" >/dev/null 2>&1 || true
    xcrun simctl delete "$simulator" >/dev/null 2>&1 || true
  fi
  rm -f "$selection" "$selection.selected"
  exit "$code"
}
trap cleanup EXIT
python3 - "$selection" > "$selection.selected" <<'SELECT'
import json,sys
state=json.load(open(sys.argv[1]))
runtimes=[r for r in state['runtimes'] if r.get('isAvailable') and '.iOS-' in r['identifier'] and int(r['version'].split('.')[0])>=26]
runtimes.sort(key=lambda r:tuple(map(int,r['version'].split('.'))),reverse=True)
for runtime in runtimes:
    for device in state['devices'].get(runtime['identifier'],[]):
        if device.get('isAvailable') and device['name'].startswith('iPhone') and device.get('deviceTypeIdentifier'):
            print(runtime['identifier']); print(device['deviceTypeIdentifier']);sys.exit(0)
raise SystemExit('No preinstalled available iOS 26+ iPhone simulator; no runtime will be downloaded')
SELECT
runtime=$(sed -n '1p' "$selection.selected")
device_type=$(sed -n '2p' "$selection.selected")
rm -f "$selection.selected"
simulator=$(xcrun simctl create "Smart Choice read-only checks" "$device_type" "$runtime")
xcrun simctl boot "$simulator"
xcrun simctl bootstatus "$simulator" -b
swift tool/check-optional-analytics.swift
"$FLUTTER_BIN" drive --driver=test_driver/integration_test.dart --target=integration_test/landing_navigation_test.dart -d "$simulator"
# Integration changes the app entry point. Rebuild and install the normal app.
"$FLUTTER_BIN" build ios --simulator --debug --target=lib/main.dart
xcrun simctl terminate "$simulator" com.justsmartchoice.mobile >/dev/null 2>&1 || true
xcrun simctl install "$simulator" build/ios/iphonesimulator/Runner.app
xcrun simctl status_bar "$simulator" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl launch "$simulator" com.justsmartchoice.mobile
sleep 12
mkdir -p dist/ios-simulator
xcrun simctl io "$simulator" screenshot dist/ios-simulator/iphone-home.png
printf 'Public navigation checks completed on %s. Home PNG is a simulator image, not a physical device test.\n' "$runtime"
