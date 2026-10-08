# Smart Choice Mobile

Editable Flutter Android wrapper for **https://mobile.justsmartchoice.com/admin**.
This new app has package ID `com.justsmartchoice.mobile`, so it can coexist with
the old MightyWeb APK. No original app source or builder account is required.

The hostname is not configured yet. The app shows a connection message with
Retry until it becomes available; it never falls back to production or dev.
This project does not create DNS, a Bluehost checkout, or a CRM database.

## Run and build

Requires Flutter **3.47.6** (Dart 3.13.5), Android Studio with its Android SDK,
and an Android emulator/phone running Android 10 / API 29 or newer.
Use Java **21**, AGP **8.13.2**, Kotlin **2.2.20** and Gradle **8.14.3** (pinned
in this project for compatibility with the stable WebView plugin). Flutter on
this Mac uses `/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home`.
If Android Studio asks for a Gradle JDK, select Java 21 rather than its bundled
Java 25. Set Flutter's JDK on other machines with `flutter config --jdk-dir=...`.

On this Mac Flutter is installed at `/Users/mugdho/Development/flutter/bin/flutter`.
Scripts also find it under `$HOME/Development/flutter/bin/flutter` if not on PATH.

```sh
cd /Users/mugdho/smart_projects/smart-choice-mobile
./tool/check.sh
./tool/run.sh -d emulator-5554
./tool/build-apk.sh
```

Open the project directory in Android Studio or VS Code with Flutter/Dart support.
While `run.sh` is running, press `r` for hot reload or `R` for hot restart.
Before the hostname is configured, the native offline smoke test can be run with:

```sh
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/offline_launch_test.dart -d emulator-5554
```

It saves an actual emulator app screenshot to `dist/screenshots/`. Do not run
this offline-only test against an available mobile website.
The build script produces `dist/smart-choice-mobile-debug.apk`: drag it onto the
emulator or install it on a testing phone. This is a debug-signed testing APK,
not a Play Store release. Run `flutter devices` to find device IDs.

## Behavior

- Minimal CRM-colored toolbar with back/close, refresh and app information.
- Existing CRM login, cookies, forms and staff/customer permissions remain in
  the WebView. There is no independent native login or permission bypass.
- Mobile CRM and `meet.jit.si` pages remain in the app. Other HTTPS, telephone
  and email links open externally. Production/dev CRM navigation is blocked.
- User-initiated popup windows and Android file-picker uploads are supported.
- Camera/microphone permission requests are limited to the mobile CRM and
  Jitsi, and use Android runtime permission prompts. Nothing is requested at
  startup. Denied permissions remain denied.
- Authenticated GET downloads use applicable WebView cookies and save through
  Android MediaStore to `Downloads/SmartChoice` with an Open action. No broad
  storage permission is needed. Redirects cannot forward cookies outside the
  mobile CRM. Downloads are limited to 100 MB and reject HTML login responses.
- HTTPS/certificate validation stays enabled. Cleartext/mixed content and
  app-local session backups are disabled. There is no ad SDK or remote builder.

Server-generated GET/PDF downloads are supported. JavaScript `blob:` downloads
and documents requiring replaying a POST are not implemented. Verify actual
download routes once the mobile site is available. Refreshing a CRM page can
resubmit a form; the wrapper never automatically retries form submissions.

## Source and delivery

Keep the app in its own GitHub repository, using `dev` for mobile development
and `main` for approved releases. Commit source, `pubspec.lock`, tests and build
scripts. Do not commit build outputs, SDK paths, signing keys or private data.
This initial project has no GitHub remote configured.

The included GitHub Actions workflow checks formatting, analysis and tests,
then builds a debug APK artifact on dev/main pushes and pull requests.

| Change | How it reaches testers |
| --- | --- |
| CRM PHP/CSS/JavaScript | Deploy to the separate mobile Bluehost checkout, then reload the app |
| Native UI, permissions, icon or plugins | Build and install a new APK |
| GitHub push | Runs CI; does not update an installed app automatically |

Configure the mobile site's DNS, HTTPS certificate, CRM base URL and separate
checkout later. Decide database isolation before write-based testing; this
app does not configure or share a CRM database itself.

## Release checklist

Configure a private release-signing key before distribution. Gradle intentionally
does not sign release builds with a developer debug key. The old APK cannot be
upgraded in place because its package/signing identity is different.

After the mobile site exists, verify login/logout persistence, permissions,
CSRF forms, uploads, actual document downloads, popup/back navigation and
Jitsi on two real Android phones. A successful build does not prove live
meeting audio/video or invitation delivery. Keep payment/approval/signature
testing away from production data.
