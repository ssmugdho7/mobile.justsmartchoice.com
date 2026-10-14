#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Source and Foundation checks only; this does not replace an iOS/Xcode build.
ruby -c ios/Podfile
plutil -lint ios/Runner/Info.plist ios/Flutter/AppFrameworkInfo.plist ios/Runner.xcodeproj/project.pbxproj
swiftc -frontend -parse ios/Runner/AppDelegate.swift ios/Runner/DocumentStore.swift
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/smart-choice-ios-check.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT
swiftc -module-cache-path "$check_dir/modules" ios/Runner/DocumentStore.swift tool/ios-document-store-checks.swift -o "$check_dir/document-checks"
"$check_dir/document-checks"
python3 - <<'ICON_CHECK'
import json
from pathlib import Path
import struct
folder = Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
assets = json.loads((folder/'Contents.json').read_text())['images']
for asset in assets:
    data = (folder/asset['filename']).read_bytes()
    width, height, depth, color_type = struct.unpack('>IIBB', data[16:26])
    expected = round(float(asset['size'].split('x')[0]) * float(asset['scale'][:-1]))
    assert (width, height) == (expected, expected), asset['filename']
    assert color_type == 2, 'App icons must be opaque RGB PNGs'
print(f'{len(assets)} iOS icon declarations verified (size and no alpha)')
ICON_CHECK
