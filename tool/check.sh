#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
"$FLUTTER_BIN" pub get
"$(dirname "$FLUTTER_BIN")/dart" format --output=none --set-exit-if-changed lib test integration_test test_driver
"$FLUTTER_BIN" analyze
"$FLUTTER_BIN" test
