#!/usr/bin/env bash
# Run only on a private/disposable macOS builder after Apple membership renewal.
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."
. ./tool/flutter-bin.sh
for name in IOS_TEAM_ID IOS_DISTRIBUTION_P12_BASE64 IOS_DISTRIBUTION_PASSWORD IOS_PROFILE_BASE64 IOS_BUILD_NUMBER; do
  if [ -z "${!name:-}" ]; then echo "Missing private release input: $name" >&2; exit 1; fi
done
[[ "$IOS_BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] || { echo 'Use a unique positive integer build number.' >&2; exit 1; }
xcodebuild -version >/dev/null
sdk_version=$(xcrun --sdk iphoneos --show-sdk-version)
(( ${sdk_version%%.*} >= 26 )) || { echo 'Select an iOS 26+ SDK.' >&2; exit 1; }
python3 tool/test-ios-release.py
# Preserve previous outputs and prevent a stale IPA from satisfying validation.
python3 - <<'FRESH'
from pathlib import Path
if list(Path('build/ios/ipa').glob('*.ipa')):
    raise SystemExit('Existing IPA output found. Move it to a private archive before starting a new signed build.')
FRESH
work=$(mktemp -d "${TMPDIR:-/tmp}/smart-choice-signing.XXXXXX")
project=ios/Runner.xcodeproj/project.pbxproj
cp "$project" "$work/project.original"
security list-keychains -d user > "$work/keychains.original"
keychains=()
while IFS= read -r entry; do keychains+=("$entry"); done < <(python3 - "$work/keychains.original" <<'KEYCHAINS'
import shlex,sys
for item in shlex.split(open(sys.argv[1]).read()): print(item)
KEYCHAINS
)
keychain="$work/release.keychain-db"
profile_path=''
cleanup() {
  code=$?
  cp "$work/project.original" "$project"
  security list-keychains -d user -s "${keychains[@]}" >/dev/null 2>&1 || true
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  if [ -n "$profile_path" ]; then
    if [ -f "$work/profile.previous" ]; then cp "$work/profile.previous" "$profile_path"; else rm -f "$profile_path"; fi
  fi
  rm -rf "$work"
  exit "$code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
python3 - "$work" <<'DECODE'
import os,base64,sys
from pathlib import Path
folder=Path(sys.argv[1])
for key,name in [('IOS_DISTRIBUTION_P12_BASE64','distribution.p12'),('IOS_PROFILE_BASE64','profile.mobileprovision')]:
    (folder/name).write_bytes(base64.b64decode(os.environ[key],validate=True))
DECODE
security cms -D -i "$work/profile.mobileprovision" > "$work/profile.plist" 2> "$work/profile-decode.log"
openssl pkcs12 -in "$work/distribution.p12" -clcerts -nokeys -passin env:IOS_DISTRIBUTION_PASSWORD -out "$work/certificate.pem" 2> "$work/certificate.log"
openssl x509 -in "$work/certificate.pem" -checkend 0 -noout >/dev/null
openssl x509 -in "$work/certificate.pem" -outform DER -out "$work/certificate.der"
profile_uuid=$(python3 tool/validate-ios-profile.py "$work/profile.plist" "$work/certificate.der" "$work/ExportOptions.plist")
profile_folder="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profile_folder"
profile_path="$profile_folder/$profile_uuid.mobileprovision"
if [ -f "$profile_path" ]; then cp "$profile_path" "$work/profile.previous"; fi
cp "$work/profile.mobileprovision" "$profile_path"
keychain_password=$(openssl rand -hex 32)
security create-keychain -p "$keychain_password" "$keychain" > "$work/keychain.log" 2>&1
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$work/distribution.p12" -k "$keychain" -P "$IOS_DISTRIBUTION_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security >> "$work/keychain.log" 2>&1
security list-keychains -d user -s "$keychain" "${keychains[@]}"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >> "$work/keychain.log" 2>&1
# Apply manual signing to Runner Release only; restore original source on exit.
plutil -convert xml1 -o "$work/project.plist" "$project"
IOS_PROFILE_UUID="$profile_uuid" python3 - "$work/project.plist" "$project" <<'PROJECT'
import os,plistlib,sys
from pathlib import Path
project=plistlib.loads(Path(sys.argv[1]).read_bytes()); objects=project['objects']
targets=[v for v in objects.values() if v.get('isa')=='PBXNativeTarget' and v.get('name')=='Runner']
if len(targets)!=1: raise SystemExit('Cannot identify the app target')
configs=objects[targets[0]['buildConfigurationList']]['buildConfigurations']
release=[objects[c]['buildSettings'] for c in configs if objects[c]['name']=='Release']
if len(release)!=1: raise SystemExit('Cannot identify the release configuration')
settings=release[0]
if settings.get('PRODUCT_BUNDLE_IDENTIFIER')!='com.justsmartchoice.mobile': raise SystemExit('Unexpected app bundle identifier')
settings.update(DEVELOPMENT_TEAM=os.environ['IOS_TEAM_ID'],CODE_SIGN_STYLE='Manual',CODE_SIGN_IDENTITY='Apple Distribution',PROVISIONING_PROFILE_SPECIFIER=os.environ['IOS_PROFILE_UUID'])
Path(sys.argv[2]).write_bytes(plistlib.dumps(project,sort_keys=False))
PROJECT
"$FLUTTER_BIN" build ipa --release --build-number "$IOS_BUILD_NUMBER" --export-options-plist "$work/ExportOptions.plist"
# Flutter may report command success after an export failure. Require the IPA.
python3 tool/verify-ios-export.py build/ios/ipa "$IOS_BUILD_NUMBER"
archive_app=build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app
codesign --verify --deep --strict "$archive_app" > "$work/signature.log" 2>&1
codesign -d --entitlements :- "$archive_app" > "$work/entitlements.plist" 2>> "$work/signature.log"
python3 - "$archive_app/Info.plist" "$work/entitlements.plist" <<'VERIFY'
import os,plistlib,sys
from pathlib import Path
info=plistlib.loads(Path(sys.argv[1]).read_bytes())
entitlements=plistlib.loads(Path(sys.argv[2]).read_bytes())
if info.get('CFBundleIdentifier')!='com.justsmartchoice.mobile' or str(info.get('CFBundleVersion'))!=os.environ['IOS_BUILD_NUMBER']:
    raise SystemExit('Signed archive bundle/build mismatch')
if entitlements.get('com.apple.developer.team-identifier')!=os.environ['IOS_TEAM_ID'] or entitlements.get('get-task-allow',False):
    raise SystemExit('Signed archive entitlement mismatch')
VERIFY
# No uploading, new certificates, profile generation, agreement or payment here.
echo 'Signed archive verified and fresh IPA exported. Apple validation and device checks remain required.'
