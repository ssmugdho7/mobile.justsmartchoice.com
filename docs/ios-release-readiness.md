# Smart Choice Mobile — page audit and iOS preparation

Android/preview repairs and iOS native implementation, version 0.5.4+9.

Source: this repository, https://github.com/ssmugdho7/mobile.justsmartchoice.com.
Local checkout: `/Users/mugdho/smart_projects/smart-choice-mobile`.
`lib/main.dart` is the installed app; `lib/preview_main.dart` is the browser preview.
`lib/` contains shared UI; `ios/` and `android/` contain native implementations.
This is separate from the PHP CRM repository. Existing accounts/data stay on the live CRM.

## Repairs

| Area | Change |
| --- | --- |
| Appointment shortcuts | Quick menu uses the same public booking route as Home. |
| Browser preview | Reopening a portal resets its requested start page. Fifteen public Shop/policy/resource snapshots avoid CSP frame blocking. Unknown public pages recover inside the app. |
| Settings | Scrollable on short screens; About, Privacy Policy, Terms and client Account privacy remain accessible. |
| Permissions | iOS combined camera/microphone capture grants only when both OS permissions succeed. Browser delegation allows only exact CRM/Jitsi origins; user prompts still apply. |
| Downloads | iOS Files save/open implementation; bounded sandbox-only files, preserved duplicates, protected storage and backup exclusion. Public listed Toolbox PDFs use a separate cookie-free download path. Invalid PDF bytes, insecure redirects and unrelated cookies are rejected. |
| iOS popup links | WebKit has no gesture metadata; valid user windows can open while automatic JavaScript popups remain disabled. Android still requires an explicit gesture. |
| Errors | Download failures and missing phone/email handlers give feedback; saved-file location matches the platform. |
| Branding | Opaque Smart Choice iOS icons and launch assets replace Flutter template graphics. |
| iOS dependencies | Native CocoaPods installation/configuration and camera/microphone build flags added. |

The existing CRM enables client registration, GDPR and contact-removal requests (read-only configuration check). Settings → Account privacy opens `/clients/gdpr` within the app. This initiates the CRM's existing manual removal workflow; no removal request or deletion was performed. Before release, verify the client-facing flow and owner fulfilment process with an approved disposable account, including confirmation, timing and retained records. Do not present a submitted request as completed deletion.

## Executed checks

| Check | Result |
| --- | --- |
| `npm ci --ignore-scripts` | Installed locked dependencies; npm reported zero vulnerabilities. |
| `./tool/check.sh` | Formatter/analyzer clean; 66 Flutter tests and 33 JavaScript checks passed. |
| `flutter test --platform chrome test/embedded_page_web_test.dart` | Two real-DOM permission-policy checks passed; no media started. |
| `./tool/check-ios-source.sh` | 28 Foundation/macOS document-storage checks, Swift parse, Ruby/Podfile/plist/project lint, 19 opaque icon sizes passed. These are not iPhone tests. |
| Android `landing_navigation_test.dart` | Shop → Privacy/Terms → Toolbox → Contact → Appointment/provider lookup → Client → Employee → About; passed without submissions. |
| Android `toolbox_navigation_test.dart` | Calculator result, Toolbox return, Progressive inside app and missing-document recovery passed. |
| `./tool/build-preview.sh --base-href /` | Release web preview built; in-app browser confirmed Privacy loads inline and missing policy recovers. |
| Normal Android build/startup | Normal lib/main.dart APK rebuilt/validated and running with hot reload; denied microphone, notification and camera prompts still led to Home. Settings → Account privacy stays in-app and requires client login; no removal submitted. |
| Public Toolbox link probe | All 28 card targets checked with GET; remote errors recorded below. No transactions, chat messages, uploads or bookings sent. |
| iOS release compilation | Unsigned GitHub build passed with Xcode 26.6/iPhoneOS SDK 26.5: Runner.app (20.1 MB), including native UIKit code and CocoaPods dependencies. [Build evidence](https://github.com/ssmugdho7/mobile.justsmartchoice.com/actions/runs/38635135471) for app commit 407af81. Android CI and the public preview workflow also passed for that revision. Local full Xcode remains absent. |

## Website/provider dependencies

Three linked website policies return HTTP 404: `/accessibility.php`, `/payment-refund-policy.php`, `/sms-communications-policy.php`. Two agreement pages and five linked form PDFs were already missing. App recovery is implemented; missing business documents have not been invented or labelled working.

The read-only Toolbox probe received HTTP 403 from Simply Business, TrustedChoice, CareerSafe and the Seminole County PDF URL. A provider's anti-bot rules can treat normal device browsers differently; these responses do not prove malware or an app bug. Browser preview uses an explicit provider website action. Native HTTPS navigation remains in-app; unavailable responses have recovery. Actual provider document availability remains a release check.

## Apple submission gates

For local iOS development/simulator testing, install full Xcode. A private owner-controlled cloud signing/TestFlight pipeline is also possible and does not require Xcode on this Mac.

Do not label this app App Store ready until these gates pass:

1. **Native build:** unsigned CI compilation passed; meet the current SDK requirement in local Xcode or a private owner-controlled signing pipeline; build a signed archive with the owner's Apple team and validate it in Organizer. `./tool/check-ios-build.sh` checks SDK ≥26 and compiles without signing. It cannot upload or produce a signed IPA.
2. **Account access:** owner has Apple Developer/App Store Connect access and will provide it later. Configure `com.justsmartchoice.mobile`, distribution signing, App Store Connect app record and version/build privately. No Apple keys, certificates or passwords go into Git.
3. **Physical iPhone and iPad:** test launch, safe areas/rotation/text sizing, Staff and Client login/logout/7-day remember behavior, profile menus, file selection/camera uploads, GET and POST PDF save/open/share, denied permissions, user-initiated popup links, offline/retry, and a two-person Jitsi audio/video call. Android/Chrome results do not verify these.
4. **Deletion:** test Settings → Account privacy and real client-removal fulfilment on an approved disposable account. Client registration is enabled, so a working deletion initiation flow is required; email-only instructions or deactivation alone are insufficient.
5. **Privacy:** complete accurate App Privacy disclosures for the app **and** live CRM/website/meeting/chat providers; inspect privacy manifests in the archive/dependencies and required-reason API report. The native app stores theme/permission preferences and platform cookies; downloaded documents are kept in the user's Files folder. Do not claim no data collection just because Flutter has no analytics SDK. Determine whether website tracking requires ATT before enabling it in the release.
6. **Content and review:** repair required missing policies/documents, supply working support/privacy URLs, screenshots/age rating/export-compliance answers, and private staff/client review accounts with safe records. Explain useful CRM functions (documents, appointments, uploads and meetings). A WebView wrapper is subject to Apple's minimum-functionality review; approval is not guaranteed.
7. **Social login:** currently not configured. Before enabling Google/Facebook as a primary login, review Apple's equivalent-login requirement and implement/test the appropriate Apple option when applicable.
8. **TestFlight:** upload the signed build, invite testers, resolve device crashes/feedback and only then submit for App Review. Do not use production payments, signatures or notifications as test fixtures.

Apple references: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [SDK minimum requirement](https://developer.apple.com/news/?id=ueeok6yw), [account deletion guidance](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/), [privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).

## Reproduce and release

```sh
npm ci --ignore-scripts
./tool/check.sh
flutter test --platform chrome test/embedded_page_web_test.dart
./tool/check-ios-source.sh
./tool/check-ios-build.sh # requires full Xcode; unsigned compile only
```

Use the existing Flutter drive commands in README for Android checks. After any integration run, rebuild the normal `lib/main.dart` entry point with `JAVA_HOME` pointing to Java 21 and `./tool/build-apk.sh`, then `./tool/run.sh -d emulator-5554`. Never distribute an integration-test entry point.

Development source uses `origin/dev`. Main, Bluehost distribution and App Store publication need their release instruction/signing gates; this audit does not publish an App Store app or change CRM data/settings.
