#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
"$FLUTTER_BIN" build web --target lib/preview_main.dart "$@"
mkdir -p build/web/public-pages
cp -R preview_site/. build/web/public-pages/
