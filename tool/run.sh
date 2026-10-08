#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
exec "$FLUTTER_BIN" run "$@"
