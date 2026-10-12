# Toolbox navigation verification — 2026-10-13

Scope: all 28 Toolbox cards in the mobile browser preview, public HTTP link checks, calculator execution, and Android navigation. Public resources only; no production bookings, signatures, quotes, payments or notifications submitted.

## Causes and repairs

- Six calculator cards pointed to nonexistent root URLs. The files exist under `/calculators/`. Native GET navigation now resolves those paths; browser preview has interactive public snapshots. Relative CSS/images are corrected without changing third-party pages.
- Forms and Contracts enforce same-origin framing. The preview now uses public snapshots; server frame restrictions remain intact. Notice of Commencement anchors are retained.
- Two agreement pages and five public PDF files referenced by Forms Library are absent (HTTP 404). Recovery names the missing resource and offers Forms Library / Toolbox; it does not substitute another agreement.
- External providers can deny framing. Browser preview has an explicit user-initiated website action and Back to Toolbox. Android loads provider pages in its own WebView. Toolbox cards use the current WebView.
- The missing standalone Notice of Commencement guide routes to the existing Forms Library NOC section.
- Calculator Back buttons return to Toolbox, and the Fractions page's old Concrete URL resolves to the existing calculator.

## Card results

All 28 cards were clicked before and after the change in the browser interface. HTTP status below is a direct public request to the resolved destination, not a promise of provider availability.

| Card | HTTP status | App/preview outcome |
| --- | --- | --- |
| General Construction Calculator | 200 | Inline public page; corrected calculator path where applicable |
| Concrete Calculator | 200 | Inline public page; corrected calculator path where applicable |
| Feet & Inches Calculator | 200 | Inline public page; corrected calculator path where applicable |
| Flooring Calculator | 200 | Inline public page; corrected calculator path where applicable |
| Fractions Calculator | 200 | Inline public page; corrected calculator path where applicable |
| Paint Calculator | 200 | Inline public page; corrected calculator path where applicable |
| Vinyl Fence Calculator | 200 | Inline public page; corrected calculator path where applicable |
| Pricing Guide | 200 | Inline public page; corrected calculator path where applicable |
| Construction Pros Insurance | 200 | Provider information with explicit website action; native stays in WebView |
| Simply Business | 403 | Provider information with explicit website action; native stays in WebView |
| Progressive Commercial | 200 | Provider information with explicit website action; native stays in WebView |
| The Hartford Contractor Insurance | 200 | Provider information with explicit website action; native stays in WebView |
| FWCJUA | 200 | Provider information with explicit website action; native stays in WebView |
| TrustedChoice.com | 403 | Provider information with explicit website action; native stays in WebView |
| OSHA Construction Outreach Training | 200 | Provider information with explicit website action; native stays in WebView |
| OSHA Authorized Online Providers | 200 | Provider information with explicit website action; native stays in WebView |
| USF OSHA Training Institute | 200 | Provider information with explicit website action; native stays in WebView |
| ABC Central Florida Safety Training | 200 | Provider information with explicit website action; native stays in WebView |
| CareerSafe OSHA 10 Construction | 403 | Provider information with explicit website action; native stays in WebView |
| OSHA.com / 360training | 200 | Provider information with explicit website action; native stays in WebView |
| Notice of Commencement Guide | 200 | Inline public page; corrected calculator path where applicable |
| Subcontractor Agreement | 404 | Unavailable message with Forms Library / Toolbox recovery (source is 404) |
| Construction Renovation Agreement | 404 | Unavailable message with Forms Library / Toolbox recovery (source is 404) |
| Forms Library | 200 | Inline public page; corrected calculator path where applicable |
| Florida Payment Forms | 200 | Provider information with explicit website action; native stays in WebView |
| Construction Change Order Sample | 403 | Provider information with explicit website action; native stays in WebView |
| Lien Waiver Template | 200 | Provider information with explicit website action; native stays in WebView |
| Government Contracts & Bids | 200 | Inline public page; corrected calculator path where applicable |

## Provider limits

CareerSafe and some other providers returned 403 to direct requests. Seminole County returned an explicit region restriction. These provider decisions remain in force. The explicit website action preserves access to the original provider; no security headers, certificates, CAPTCHA, or access restrictions were bypassed.

## Verification

- Flutter analysis and unit/widget tests.
- JavaScript tests: all six calculator examples, Forms/Contracts snapshots, navigation bridge, Back button, and native link targeting; existing PDF/CSRF/trust tests retained.
- Browser: 28 card clicks, calculator `2 + 3 = 5`, Back to Toolbox, Progressive website action opens the actual provider page while preserving preview.
- Android emulator integration: calculator resolution, arithmetic, corrected asset paths, Back to Toolbox, Concrete card, Progressive in-app navigation, and missing agreement recovery.

Public page snapshots are refreshed with `node tool/refresh-public-pages.cjs <page-name>`. Public link status can be rechecked with `node tool/audit-toolbox.cjs <output.json>`.

APK publication validates that the normal Dart program is present and integration-test entry points are absent. A packaging failure after local disk exhaustion was caught in the emulator, the download was rolled back, and the normal APK was rebuilt from clean artifacts.
