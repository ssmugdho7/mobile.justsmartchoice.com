#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
"$FLUTTER_BIN" build apk --debug --target-platform android-arm64 "$@"
mkdir -p dist
cp build/app/outputs/flutter-apk/app-debug.apk dist/smart-choice-mobile-debug.apk
python3 - <<'BUILD_METADATA'
import hashlib, json, pathlib, subprocess
apk = pathlib.Path('dist/smart-choice-mobile-debug.apk')
with apk.open('rb') as f:
    hasher = hashlib.sha256()
    for chunk in iter(lambda: f.read(1024 * 1024), b''):
        hasher.update(chunk)
    digest = hasher.hexdigest()
pathlib.Path('dist/build-source.json').write_text(json.dumps({
    'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
    'sha256': digest
}) + '\n')
BUILD_METADATA
echo "APK: $(pwd)/dist/smart-choice-mobile-debug.apk"
