# Smart Choice Mobile — App Store listing

Store copy and private review worksheet for the first iOS release.

Prepared 15 October 2026. This document is a draft for App Store Connect. No app record, public metadata, review submission or release is created by this file. Use the signed build actually tested on iPhone/iPad when completing the listing.

## Proposed identifiers and listing fields

| Field | Prepared value |
| --- | --- |
| App name | Smart Choice Mobile |
| Bundle ID | `com.justsmartchoice.mobile` |
| SKU | `smart-choice-mobile` |
| Primary language | English (U.S.) |
| Subtitle | Projects and appointments |
| Primary category | Business — owner confirmation required |
| Support URL | https://justsmartchoice.com/contacts.php |
| Privacy Policy URL | https://justsmartchoice.com/privacy.php |
| Marketing URL | https://mobile.justsmartchoice.com/ |
| Copyright | Owner to confirm the exact rights holder and year; do not infer from the Apple account holder's name. |

App name availability, Bundle ID registration and SKU uniqueness must be checked in the owner's Apple team. The privacy policy is publicly accessible, but the mobile/processor/deletion details in [App Store privacy](app-store-privacy.md) still need confirmation before submission.

**Keywords** — 84 characters:

```text
crm,construction,contractor,projects,appointments,documents,customer,service,roofing
```

**Promotional text** — 136 characters:

```text
Access Smart Choice projects and documents, book a service appointment, contact the office and join available video meetings in one app.
```

The subtitle is 25 characters. Revalidate all limits if this copy changes.

## Description

```text
Smart Choice Mobile connects Smart Choice Contractors USA customers and employees to the company's CRM.

Customers can use their account to access authorized project information, documents and communications. Employees can open the staff portal and work with the features their role permits.

• Book a service appointment.
• Review available project information and CRM documents.
• Upload photos or files where your account has permission.
• Save available documents to Files for later access.
• Contact the office and access business tools.
• Join available video meetings.
• Access account privacy options inside the app.

The app includes separate employee and customer entry points, an in-app browser, a light/dark appearance setting and document-saving controls. Your existing CRM account and server permissions determine what you can access.

An internet connection is required. Camera and microphone access are requested when you choose a supported upload or video meeting. The app does not require permission approval to open its Home screen.
```

This copy describes implemented capabilities. Physical-device verification remains required, especially uploads, Files opening/sharing and video meetings. Remove a feature from the listing if the final release does not pass its device check. Do not advertise push notifications: asking Android for permission does not implement a push service.

## Review notes draft

Supply the owner fields below privately in App Store Connect. These are required information fields, not sample credentials. Do not put passwords, customer records or account tokens in this repository.

```text
Smart Choice Mobile is a customer and employee app for Smart Choice Contractors USA. It opens the company's live CRM at crm.justsmartchoice.com. The Home screen has Employee Login, Client Login, Book an Appointment, Contact Us, Toolbox and Shop entry points.

Staff and customer roles have different permissions. Please use the separate review accounts supplied in the Sign-in Information fields. Their records must be safe review fixtures, without customer personal information.

Employee access: Home → Employee Login → sign in with the staff review account.
Customer access: Home → Client Login → sign in with the customer review account.
Account deletion initiation: Home → Settings → Account privacy → sign in as the customer → the CRM account privacy page. The owner must supply the tested deletion steps, fulfilment time and confirmation process below before review.

Camera and microphone access are requested for a user-chosen upload or supported video meeting. Declining access does not block the Home screen. Files downloads use the app's SmartChoice folder in Files.

The app provides native Home/navigation, appearance controls and document save/open functionality around the authorized CRM workflows. The CRM remains responsible for sessions, account roles and record ownership.

Optional Google Analytics and Ahrefs requests are blocked in the installed app. This does not disable the CRM's functional server-side records or security services.
```

Before using these notes, add the actual safe reviewer workflow and controlled appointment/meeting records. Reviewers must be able to exercise the app without production customer transactions.

| Private owner field | Required content |
| --- | --- |
| Review contact | Real name, business email and phone where App Review can reach the owner. |
| Staff review sign-in | Dedicated permitted account and its private password in Apple's sign-in fields. |
| Customer review sign-in | Dedicated customer account and its private password in Apple's sign-in fields. |
| Access instructions | Any ordinary CAPTCHA/MFA requirements and how a reviewer completes access; do not claim a bypass that does not exist. |
| Safe test records | Non-customer project/document fixtures; an approved meeting plan and upload test target. |
| Deletion workflow | Tested customer steps, reasonable processing time, completion confirmation and legally retained data. |
| Permissions | Explain which features are deliberately unavailable to each review role. |

## Screenshots and preview plan

Capture the actual signed app on each required device/display family selected in App Store Connect. Use safe fixtures and redact no data by inventing a screen that the app does not render.

Suggested screenshots:

1. Six-button Home and Smart Choice branding.
2. Customer portal with safe project information.
3. Appointment service/provider selection without a production booking.
4. Document view and the native saved-document control.
5. Staff portal with a safe project or authorized work view.
6. Toolbox or a supported video meeting after the real-device check.

Include no passwords, private email addresses, customer documents, signing identifiers or real customer images. Android emulator and browser-preview screenshots do not establish an iOS device result.

## Owner decisions and release gates

- Confirm name/category, copyright holder, price and distribution territories.
- Complete the current age-rating questionnaire for the actual enabled content, private communications and embedded website access; do not infer an age rating from the Business category alone.
- Confirm commercial/payment behavior. Native source has no StoreKit or digital-subscription feature; linked website/CRM offerings still need review.
- Confirm export compliance for the final archive. Current native code uses platform HTTPS and does not implement custom encryption; answer from the built dependency set and owner's distribution requirements.
- Renew Apple Developer Program membership and confirm active status before distribution signing/upload.
- Create the app record, obtain private distribution signing, produce a signed archive, inspect its privacy report and upload to TestFlight.
- Finish iPhone/iPad acceptance checks, deletion verification and the required owner decisions in [App Store privacy](app-store-privacy.md).
- Submit for App Review only after these gates pass. Source checks and an unsigned build are not App Store approval.

See [iOS release readiness](ios-release-readiness.md) for the actual test evidence and remaining device checks.
