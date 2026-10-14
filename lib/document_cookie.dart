import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'navigation_policy.dart';

/// Filters the platform cookie result before exporting a CRM document.
/// WKHTTPCookieStore's plugin adapter matches host suffixes without a label
/// boundary and does not filter paths or expiration dates.
class DocumentCookies {
  static String header(
    Uri uri,
    Iterable<Cookie> cookies, {
    DateTime? now,
    bool allowMissingDomain = false,
  }) {
    if (!NavigationPolicy.isCrm(uri)) return '';
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final path = uri.path.isEmpty ? '/' : uri.path;
    final eligible = <Cookie>[];
    for (final cookie in cookies) {
      final domain = cookie.domain?.toLowerCase();
      if (domain == null || domain.isEmpty) {
        // Older Android WebViews expose only a header already scoped by their
        // native CookieManager. iOS always supplies domain metadata.
        if (!allowMissingDomain) continue;
      } else {
        final normalized = domain.startsWith('.')
            ? domain.substring(1)
            : domain;
        if (normalized.isEmpty ||
            (uri.host != normalized &&
                (!domain.startsWith('.') ||
                    !uri.host.endsWith('.$normalized')))) {
          continue;
        }
      }
      if (cookie.isSecure == true && uri.scheme != 'https') continue;
      if (cookie.expiresDate != null && cookie.expiresDate! <= timestamp) {
        continue;
      }
      final cookiePath = cookie.path;
      if (cookiePath != null &&
          cookiePath.isNotEmpty &&
          (path != cookiePath &&
              (!path.startsWith(cookiePath) ||
                  (!cookiePath.endsWith('/') &&
                      (path.length <= cookiePath.length ||
                          path[cookiePath.length] != '/'))))) {
        continue;
      }
      if (!RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$").hasMatch(cookie.name) ||
          cookie.value is! String ||
          RegExp(r'[;\r\n]').hasMatch(cookie.value as String)) {
        continue;
      }
      eligible.add(cookie);
    }
    return eligible
        .map((cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');
  }
}
