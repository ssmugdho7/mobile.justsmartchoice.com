# Smart Choice Mobile — Apple signing preparation

Private signing and TestFlight setup after membership renewal.

The owner's Apple Developer account was inspected on 15 October 2026. Membership was expired; the owner chose to renew later. No renewal, payment, agreement acceptance, certificate creation/revocation, App Store app record or upload was performed. The app is not yet ready to submit for review.

## Prepared workflow

`.github/workflows/ios-release.yml` is manual-only on this repository's dev/main branches. It uses full Xcode on macos-26 and Flutter 3.47.6. The build imports an existing owner distribution certificate/profile into a temporary keychain, validates the profile's team, exact bundle, expiry, distribution type and matching public certificate, temporarily sets Runner Release signing, and restores the project/keychain search list/profile on exit. It does not create signing credentials. It refuses pre-existing IPA outputs and verifies a fresh exported IPA bundle/build plus archive signature/team/build before reporting success; Flutter archive success alone is insufficient. Signing materials and signed IPA files are not published as workflow artifacts.

`upload_to_testflight` defaults to **false**. Selecting true additionally validates and uploads the signed IPA using an existing private App Store Connect API key. Upload is a separate owner-approved action; do not select it during preparation. This workflow has not been executed with real signing materials. Synthetic metadata tests do not prove certificate trust, signing success or Apple acceptance.

## Owner setup after renewal

1. Renew the existing Apple Developer membership and complete required agreements privately.
2. Verify/register the explicit Bundle ID `com.justsmartchoice.mobile` in the correct team, and create its App Store Connect app record. Check app name and SKU availability using [listing draft](app-store-listing.md).
3. Export an existing **Apple Distribution** certificate plus private key as an encrypted `.p12` using Keychain Access. If none exists, have the owner create the required certificate; never revoke unrelated certificates to bypass a limit.
4. Create/download the matching **App Store Connect distribution** provisioning profile for this exact app and certificate. Development, ad hoc, expired and enterprise profiles are rejected.
5. In GitHub Settings → Environments create `ios-release`, restrict deployments to dev/main, configure required owner reviewers, and disable self-review where supported. The workflow environment declaration alone does not create those reviewer rules. Do this before adding credentials or dispatching signed builds. Use a private owner-controlled runner/repository if your plan cannot protect these secrets adequately.
6. Add the following environment secrets privately. Base64 is transport encoding, not encryption; never paste these values into source/chat or print them to logs.

| Secret | Required input |
| --- | --- |
| `IOS_TEAM_ID` | Correct ten-character Apple team ID |
| `IOS_DISTRIBUTION_P12_BASE64` | Base64 of the encrypted distribution certificate/private-key `.p12` |
| `IOS_DISTRIBUTION_PASSWORD` | Nonempty password for that `.p12` |
| `IOS_PROFILE_BASE64` | Base64 of the matching `.mobileprovision` |
| `ASC_KEY_ID` | Existing App Store Connect key ID; needed only for upload |
| `ASC_ISSUER_ID` | Existing key issuer ID; needed only for upload |
| `ASC_PRIVATE_KEY_BASE64` | Base64 of the existing `AuthKey_…p8`; upload only |

Scope the App Store Connect key/role as narrowly as Apple permits and verify access to this app. Do not grant broad account administration only to upload a build. A person with workflow source write access could change how secrets are used; owner environment review must inspect the selected commit.

7. Complete the privacy, retention, export compliance, age rating and review-account owner decisions in [App Privacy](app-store-privacy.md) and [listing draft](app-store-listing.md). No export-compliance exemption is asserted automatically in Info.plist. Classify the final app's encryption with Apple before answering.
8. Dispatch **Prepare signed iOS release** on the reviewed dev/main commit using a new positive integer build number and upload **false**. Inspect archive validation/signing/privacy manifests. No real signing run has been performed yet.
9. After approval, dispatch a new unique build with upload **true**. A green upload command alone does not prove processing: verify the exact version/build appears in App Store Connect. Finish TestFlight processing/export-compliance questions, iPhone/iPad and disposable-account tests, then submit for review only with owner authorization.

For a local private/disposable Mac with full Xcode, set the same signing inputs privately and run `./tool/build-ios-release.sh`. The script exports under ignored `build/ios/`; it never uploads. Shared long-lived machines need the owner's normal key-management process.

## Checks and limits

`python3 tool/test-ios-release.py` checks valid synthetic metadata and rejected team/bundle, wildcard, development, ad hoc, enterprise, dates, UUID and certificate mismatches. Export tests reject missing, empty, duplicate and wrong bundle/build IPA files. `bash -n tool/build-ios-release.sh` checks shell syntax. These checks require no account or private material. Actual signing, API authentication, TestFlight processing, physical devices and App Review remain unverified until the owner supplies access and materials.

Sources: [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios), [Apple upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [App Store Connect API](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/).
