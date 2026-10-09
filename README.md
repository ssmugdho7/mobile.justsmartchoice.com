# Smart Choice Mobile

Editable Flutter Android app for the existing **https://crm.justsmartchoice.com**.
**https://mobile.justsmartchoice.com** hosts its download page, not a second CRM.
Staff and customers use their existing accounts and records. Actions affect live
CRM data; this app does not duplicate the backend, database or authorization.
Package `com.justsmartchoice.mobile` coexists with the old MightyWeb app.

## Work on the app

Requires Flutter **3.47.6**, Dart **3.13.5**, Node **20+**, Android SDK and Java
**21**. AGP **8.13.2**, Kotlin **2.2.20** and Gradle **8.14.3** are pinned for the
stable WebView plugin. This Mac uses Flutter at
`/Users/mugdho/Development/flutter/bin/flutter` and Java at
`/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home`.

```sh
cd /Users/mugdho/smart_projects/smart-choice-mobile
npm ci --ignore-scripts
./tool/check.sh
./tool/run.sh -d emulator-5554
./tool/build-apk.sh
```

Open this folder in Android Studio/VS Code with Flutter and Dart support. During
`run.sh`, press `r` for hot reload or `R` for hot restart. Install
`dist/smart-choice-mobile-debug.apk` by dragging it onto the emulator. This is
an Android 10+ ARM64 **debug-signed testing build**, not a Play Store release.

## Behavior and safeguards

- Home and About pages with drawer navigation. Opening either preserves the CRM WebView session.
- CRM-colored toolbar: back/close, refresh, staff/customer portal switch and info.
- Server login, cookies, CSRF, roles and ownership checks remain authoritative.
- CRM and `meet.jit.si` stay inside the app. Other HTTPS, phone and email links
  open externally. Navigation/requests to the development CRM are blocked.
- Android file picker and user-initiated popup windows are supported.
- Android first launch requests microphone, notification and camera permission in that order, matching the original APK. Denial never blocks Home; the prompt sequence is not repeated on later launches. Camera/microphone use remains limited to CRM/Jitsi requests. Notification permission does not itself configure push delivery.
- HTTPS certificates remain verified; cleartext/mixed content and session backup
  are disabled. No remote app builder, ad SDK or native credential storage.
- GET downloads use scoped WebView cookies, reject external redirects and HTML
  login responses, and have a 100 MiB limit.
- The existing proposal, estimate, invoice, contract and payment **PDF-only POST
  forms** preserve CSRF/fields and save through a restricted native bridge
  (10 MiB limit). Payment, approval, signature and other submission forms are
  untouched. Generic blob exports or other custom POST downloads need separate
  implementation if encountered.
- Files save to Android `Downloads/SmartChoice` using MediaStore; no broad
  storage permission. Private staging files are deleted after save/failure.

## Verification

`check.sh` runs format, analyzer, Dart tests and PDF-form JavaScript tests.
Native read-only portal checks use the real Android WebView:

```sh
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/live_portals_test.dart -d emulator-5554
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/live_pdf_test.dart --dart-define=TEST_PROPOSAL_URL=AUTHORIZED_EXISTING_PROPOSAL_URL -d emulator-5554
```

The PDF test only downloads an existing document. Never commit document hashes,
cookies, customer PDFs or test credentials. Rebuild the normal APK after running
integration tests, which build a test entry point. Flutter-layer screenshots do
not capture the native WebView and are not full-screen visual proof.

Build/automated tests do not prove authenticated upload, logout persistence,
invitation delivery or a two-person Jitsi audio/video call. Verify these with
human login and approved records/devices; do not use production financial
transactions as smoke tests.

## GitHub and deployment

Origin: **https://github.com/ssmugdho7/mobile.justsmartchoice.com**. Work on `dev`;
use `main` for approved releases. GitHub Actions checks source and builds a test
APK artifact. Pushes do not automatically update installed apps or Bluehost.
CI testing artifacts use the runner's debug key and may not update an APK signed
on this Mac; keep using the same local debug key for website testing updates.
Stable release signing is required for a distributable update pipeline.

| Change | Delivery |
| --- | --- |
| CRM PHP/CSS/JS | Existing CRM release process; reload the app |
| Native toolbar, plugins, permissions | Build/install a new APK |
| Download page/APK | Explicit mobile website deployment |

After checking/building and committing source, publish only `website/` and the APK:

```sh
python3 tool/deploy-web.py
```

This script targets only `/home2/scusawco/public_html/mobile`, backs up replaced
files outside the public root, stages explicit files and checks APK integrity.
It preserves `.htaccess`, `.well-known`, CRM source, uploads and databases.
Versioned APK URLs prevent stale CDN/browser downloads. The command prints a rollback script location. The SSH key stays outside Git.

Keep SDK paths, generated outputs, signing keys, secrets and runtime/customer
data out of commits. Release signing must be configured privately before public
production/store distribution. The old app has a different package/signature
and cannot be upgraded by this APK.

## Daily development and client review

Run `./tool/run.sh -d <android-device-id>` once, then press `r` in that terminal after editing Dart code to hot reload. Press `R` for a full restart. Native Kotlin/Swift or plugin changes need a rebuild; ordinary Flutter screen changes do not need another APK download. `flutter devices` lists connected devices.

The shared Home/About/navigation interface has a browser entry point: `lib/preview_main.dart`. Build with `./tool/build-preview.sh --base-href /` and serve `build/web` locally for a complete browser preview. Successful `dev` pushes automatically build and publish it through `.github/workflows/preview.yml` to GitHub Pages. Client link: https://mobile.justsmartchoice.com/preview/ . Refresh that link after the workflow completes; the header identifies the source commit and build time.

This preview uses the same Flutter AppShell and navigation as the native app. Native Home loads `https://justsmartchoice.com/`; About loads `https://justsmartchoice.com/about.php`, fixing the original APK's malformed `http://about.php/`. The original black header, logo drawer and Dark Mode switch are restored. CRM shortcuts remain under the header's portal menu. Dark Mode controls the app chrome; website content retains its own design.

The public website blocks cross-domain framing and asset loading. The browser preview therefore uses copies of the two public pages and their public assets under `preview_site/`. Refresh those with `node tool/refresh-public-pages.cjs` after a website design change. Preview forms cannot submit, links open the live website separately, and analytics/chat integrations are excluded. These preview files are not bundled into Android APKs. No CRM sessions or private content are copied. Native downloads, uploads, permissions and video calls still require emulator/device testing.

The installed app loads the live public website, including its Resources/Legal footer, customer chat widget and Smart Choice Assistant (Support, Estimate and Book Appointment). Those remain website features and are not duplicated or replaced by native mock chat. The browser design preview does not send real chat messages.

CRM password visibility and Remember me use the same server implementation on web and mobile: an 8-hour workday session and the user's selected 7-day remembered login. Native WebViews retain cookies in the platform store and share them between app views; passwords are never saved in Flutter preferences. Logout is handled by the CRM and revokes its device token. After upgrading old remembered cookies, users must sign in once to establish the new bounded token.

`integration_test/live_mobile_features_test.dart` checks live public footer/assistant controls and a disposable persistent cookie across WebView recreation without logging in, sending chat, or touching CRM cookies.

The download site's source is now `website/`; `web/` is Flutter's browser build scaffold. Keep those deployment targets separate.

## Apple release preparation

An iOS project is included with the app bundle identifier and camera/microphone/photo purpose strings. It is a scaffold, not a verified iOS release: this Mac currently has Command Line Tools but not full Xcode. Before TestFlight, install Xcode, configure the private Apple signing team, implement and test the iOS document-saving channel, test WebView login/uploads/video meetings on a real iPhone, and perform App Store review preparation. Never publish debug signing keys or Apple credentials. Android's native document channel is not an iOS implementation.
