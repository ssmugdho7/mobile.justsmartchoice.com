# Smart Choice Mobile — App Store privacy

App Privacy evidence, native analytics restrictions and owner confirmation worksheet.

Prepared 15 October 2026 for release preparation for version 0.5.5+10. This is an internal disclosure worksheet, not the published legal privacy policy. App Store Connect answers must describe the final signed app and the live services it accesses.

## Selected release behavior

The owner chose to block optional Google Analytics and Ahrefs in the installed app. The native WebView release configuration blocks their known requests rather than relying on the public website's cookie banner. This applies to the installed Android/iOS app; it does not change analytics for ordinary visitors to the company's website.

The public Home HTML checked on 15 October loaded Google Analytics before the cookie-consent decision, had a later consent-controlled GA loader, and loaded Ahrefs analytics unconditionally. The app restriction addresses those optional requests in the native app. The website's duplicate/pre-consent arrangement is a separate website issue.

This restriction does not prove that all third-party tracking is absent. Other meeting, chat, CAPTCHA, payment, embedded-provider and security services still require confirmation of their actual data practices. Do not claim blanket “no tracking” from this blocker or from native SDK manifests.

The app retains these functional paths:

- `crm.justsmartchoice.com`: employee/customer sign-in and authorized CRM records, appointments, uploads, documents and communications.
- `crm.justsmartchoice.com/products/client`: the live Shop catalogue.
- `justsmartchoice.com`: public About, Contact, policy and Toolbox pages.
- `meet.jit.si`: supported video meeting pages, after a user chooses to join and grants required media permissions.
- Website assistant chat: messages post to `/AI/chat-handler.php`; a separate CRM PRChat widget also loads.
- Google reCAPTCHA: present on public client registration and other protected flows.
- External Toolbox/provider pages: HTTPS navigation chosen by the user.

No registration, chat message, production booking, payment, signature or deletion request was submitted for this privacy inventory.

## Local storage and native code

| Behavior | Source evidence |
| --- | --- |
| Appearance preference | `lib/app_shell.dart` stores the dark-mode setting using SharedPreferences. |
| Android prompt completion | `lib/startup_permissions.dart` saves the first-install prompt-completion preference. That startup sequence is not used on iOS. |
| Sign-in sessions | Native WebViews retain domain-scoped server cookies. Passwords are not saved in Flutter preferences. Server sign-in, remembered-login limits and logout remain authoritative. |
| Downloaded documents | `ios/Runner/DocumentStore.swift` saves bounded files in the app's Files → Smart Choice Mobile → SmartChoice folder, excludes them from backups and applies complete file protection. Temporary staging files are deleted. |
| Media access | Native permissions are requested for user-chosen supported uploads/meetings; camera/microphone delegation is restricted to approved CRM/Jitsi origins. |
| Native telemetry | Locked dependencies contain no separate analytics, advertising, crash-reporting or push-delivery SDK. This does not describe live website/server collection. |

On-device storage alone does not establish off-device collection. Conversely, the absence of a native analytics SDK does not make an authenticated CRM a “Data Not Collected” app.

## App Privacy inventory

The public [privacy policy](https://justsmartchoice.com/privacy.php) states that the company collects contact details, service payment information, IP/browser/browsing activity and cookies. The public client-registration form directly requests first/last name, email, phone, website/job title, company information and postal address.

| Data type | Supported path / draft purpose | Owner confirmation still needed |
| --- | --- | --- |
| Name, Email Address, Phone Number, Physical Address | Registration and appointment contact data; App Functionality. Linked to CRM account/customer records. | Whether the same data is also used for developer marketing. |
| User ID | CRM staff/contact/customer identity and authorized actions; App Functionality. Linked to the account. | Confirm all enabled account types and retention. |
| Customer Support | CRM tickets and assistant/customer support chat; App Functionality. | Chat retention, processor identity, access and whether messages reach an AI provider. |
| Other User Content | Project descriptions, notes, documents and general free text; App Functionality. | Which customer/staff features ship; retention and deletion of associated records. |
| Photos or Videos | CRM file/camera upload capability; App Functionality when retained. | Enabled upload paths, media retention, access and linked records. |
| Emails or Text Messages | Private CRM message/mail/ticket features may retain communications. | Actual enabled features and server retention; do not infer absence from the native wrapper. |
| Purchase History | CRM service invoices/transactions can expose customer purchase records. | Which transaction features ship and how records are retained. |
| Payment Info / Other Financial Info | Service-payment policy and CRM payment-related pages. | Actual entry/processor path, what the company accesses or retains, and whether collection occurs inside the app. Invoice totals alone do not prove card storage. |
| Product Interaction / Other Usage Data | Optional Google Analytics/Ahrefs requests are blocked in the installed app. | Any other retained website/CRM event collection and its purposes. Ordinary website analytics remains separate. |
| Device ID / Coarse Location / Diagnostics | CAPTCHA, security, meeting/provider and server-log practices remain to be reviewed. | Stored identifiers, IP-derived data, retention and linkage. IP address has no single automatic disclosure category. |
| Audio Data | Jitsi microphone access is supported. | Recording or retention by meeting services. A permission prompt alone does not establish retained audio collection. |
| Browsing History | Toolbox can navigate external HTTPS pages. Native code has no browsing-history database. | Assess owned-site retained navigation data separately from user-chosen open-web browsing. |

Treat these as evidence and decision prompts, not preselected App Store Connect answers. Functional contact/account records are collected even with optional analytics blocked. Account-linked records should not be marked anonymous without actual de-identification controls.

## Native privacy manifests

The cached locked SDK/framework sources were inspected. The signed archive's generated privacy report must still be checked before upload.

| Component | Actual source manifest evidence |
| --- | --- |
| Flutter iOS release framework | File timestamp reasons `0A2A.1`, `C617.1`; system boot-time reason `35F9.1`; no declared native collection/tracking. Manifest exists inside the cached signed XCFramework. |
| shared_preferences_foundation 2.5.7 | UserDefaults reason `1C8F.1`; podspec packages a privacy resource bundle. |
| permission_handler_apple 9.6.2 | UserDefaults reason `1C8F.1`; podspec packages a privacy resource bundle. |
| flutter_inappwebview_ios 1.1.2 | Manifest and privacy resource bundle; no native collected data or required-reason API categories declared. |
| url_launcher_ios 6.4.2 | Manifest and privacy resource bundle; no native collected data or required-reason API categories declared. |
| path_provider_foundation 2.6.0 | No manifest found in the cached package; inspect the final archive/native-assets implementation. Absence alone does not establish prohibited API use. |
| Runner custom code | DocumentStore reads regular-file status/file size and applies protection/backup metadata. No direct UserDefaults, system boot-time, disk-space or file-time calls were found in the audited Runner code. |

Resource-bundle declarations prove packaging intent, not the contents of the uploaded archive. SDK manifests do not replace the App Privacy answers for retained CRM or WebView data.

## Published policy and account deletion

Current Privacy Policy URL candidate: https://justsmartchoice.com/privacy.php.

The page is publicly accessible. Its policy should be reviewed for mobile local storage, actual chat/AI/meeting/payment processors, retention and account-deletion fulfilment before submission. This worksheet must not be published as a substitute for a verified company policy.

Settings → Account privacy opens `/clients/gdpr` inside the app. Previous read-only configuration checks confirmed client registration, GDPR and contact-removal settings. The disposable-account deletion request, processing and final confirmation remain untested.

Verify:

1. The customer can clearly initiate full account deletion from inside the app.
2. The interface states the reasonable processing time and any legally retained records.
3. The owner fulfils the request, deletes applicable associated personal content and confirms completion.
4. The same path is available to all customers, with appropriate identity confirmation.

A manual fulfilment process can be acceptable; a submitted request must not be described as completed deletion. Do not replace deletion with deactivation or a generic support email.

## Compact owner decision worksheet

| Decision | Owner answer needed before publishing privacy answers |
| --- | --- |
| Retention and marketing | How long are customer/staff/account, appointment, project, upload and message records retained? Which are used for marketing beyond service delivery? |
| AI/chat/meeting processors | Which services process assistant/support text and Jitsi meetings? Are messages, audio/video or recordings retained, linked to identity or used for model training/advertising? |
| Payment handling | Which payment/finance processors are active, where is information entered, and which details can Smart Choice access or retain? |
| Deletion fulfilment | Who processes client deletion, what time is promised, what must legally remain and how is completion confirmed? |
| Remaining tracking | Do any services other than the blocked optional analytics combine data with other companies' data for advertising/measurement, or share it with a data broker? |
| Review/device acceptance | Supply safe staff/customer review accounts and approve disposable-record tests; finish physical iPhone/iPad uploads, downloads, remembered login/logout and a two-person Jitsi call. |

Enter secrets only in private Apple/review/signing settings, never in this document. Copyright, seller identity, territories and store metadata belong in [App Store listing](app-store-listing.md).

## Apple guidance used

Apple requires disclosures for retained off-device data from owned WebViews and third-party partners. Local-only data and ephemeral request processing are treated separately. Tracking concerns combining data with third-party data for advertising/measurement or data brokers; a cookie choice alone does not resolve ATT when tracking applies. See [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

Apple permits a reasonable manual deletion process with a clear in-app initiation path, a disclosed processing time and completion confirmation. See [Account deletion guidance](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/).

## Validation limits

This worksheet used source/dependency inspection and read-only public HTML/policy retrieval. It does not attest to a signed archive's manifest report, a processor's undisclosed retention practices, a real iPhone call/upload, or completed account deletion. Use [iOS release readiness](ios-release-readiness.md) for actual execution evidence.
