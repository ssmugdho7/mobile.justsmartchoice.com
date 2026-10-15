import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Keep the native blocklist narrow: login, CAPTCHA, CRM and meetings remain
// available. WebKit content rules do not support regex disjunctions, so each
// domain has its own host-anchored rule with a complete URL boundary.
const optionalAnalyticsUrlFilters = [
  r'^https?://([a-z0-9-]+\.)*google-analytics\.com(:[0-9]+)?([/?#].*)?$',
  r'^https?://([a-z0-9-]+\.)*googletagmanager\.com(:[0-9]+)?([/?#].*)?$',
  r'^https?://([a-z0-9-]+\.)*analytics\.ahrefs\.com(:[0-9]+)?([/?#].*)?$',
];

final _filters = optionalAnalyticsUrlFilters
    .map((pattern) => RegExp(pattern, caseSensitive: false))
    .toList();

bool isOptionalAnalyticsRequest(Uri uri) =>
    _filters.any((filter) => filter.hasMatch(uri.toString()));

List<ContentBlocker> optionalAnalyticsContentBlockers({
  required bool usesWebKit,
}) => !usesWebKit
    ? []
    : [
        for (final filter in optionalAnalyticsUrlFilters)
          ContentBlocker(
            trigger: ContentBlockerTrigger(urlFilter: filter),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
      ];
