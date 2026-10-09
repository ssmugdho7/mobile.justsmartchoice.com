#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
"$FLUTTER_BIN" build web --target lib/preview_main.dart "$@"
mkdir -p build/web/public-pages
cp -R preview_site/. build/web/public-pages/
node <<'PREVIEW_CACHE'
const fs = require('node:fs');
const { execFileSync } = require('node:child_process');
const revision = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { encoding: 'utf8' }).trim();
const index = 'build/web/index.html';
fs.writeFileSync(index, fs.readFileSync(index, 'utf8').replace('src="flutter_bootstrap.js"', `src="flutter_bootstrap.js?v=${revision}"`));
const bootstrap = 'build/web/flutter_bootstrap.js';
const source = fs.readFileSync(bootstrap, 'utf8');
if (!source.includes('"mainJsPath":"main.dart.js"')) throw new Error('Flutter preview entry point changed; review cache versioning');
fs.writeFileSync(bootstrap, source.replace('"mainJsPath":"main.dart.js"', `"mainJsPath":"main.dart.js?v=${revision}"`));
PREVIEW_CACHE
