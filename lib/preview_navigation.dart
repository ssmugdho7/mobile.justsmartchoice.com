import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation_policy.dart';

Future<void> followPreviewLink(Uri uri, ValueChanged<Uri> onInternal) async {
  switch (NavigationPolicy.decide(uri)) {
    case NavigationDecision.internal:
      onInternal(uri);
    case NavigationDecision.external:
      // Only phone/email schemes reach the operating system, never web pages.
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    case NavigationDecision.blocked:
      return;
  }
}
