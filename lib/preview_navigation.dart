import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation_policy.dart';

Future<void> followPreviewLink(
  Uri uri,
  ValueChanged<Uri> onInternal, {
  VoidCallback? onUnavailable,
  Future<bool> Function(Uri)? launchDevice,
}) async {
  switch (NavigationPolicy.decide(uri)) {
    case NavigationDecision.internal:
      onInternal(uri);
    case NavigationDecision.external:
      // Only phone/email schemes reach the operating system, never web pages.
      try {
        final opened =
            await (launchDevice?.call(uri) ??
                launchUrl(uri, mode: LaunchMode.platformDefault));
        if (!opened) onUnavailable?.call();
      } catch (_) {
        onUnavailable?.call();
      }
    case NavigationDecision.blocked:
      return;
  }
}
