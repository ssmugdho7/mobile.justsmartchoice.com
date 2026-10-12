import 'package:flutter/material.dart';

import 'embedded_page.dart';
import 'navigation_policy.dart';
import 'preview_destination.dart';
import 'external_resource_page.dart';
import 'toolbox_unavailable.dart';

/// Live CRM pages retain their own authentication. Public website snapshots
/// avoid weakening the website's frame restrictions for the browser preview.
class PreviewPage extends StatelessWidget {
  const PreviewPage({
    super.key,
    required this.uri,
    required this.title,
    required this.onNavigate,
  });
  final Uri uri;
  final String title;
  final ValueChanged<Uri> onNavigate;

  @override
  Widget build(BuildContext context) {
    if (NavigationPolicy.isHttps(uri) &&
        !NavigationPolicy.isAppPage(uri) &&
        uri.host != NavigationPolicy.meetingHost) {
      return ExternalResourcePage(
        uri: uri,
        onBack: () =>
            onNavigate(Uri.parse('https://justsmartchoice.com/toolbox.php')),
      );
    }
    if (PreviewDestination.missingTools.contains(uri.path) &&
        NavigationPolicy.isWebsite(uri)) {
      return ToolboxUnavailable(onNavigate: onNavigate);
    }
    return Column(
      children: [
        if (NavigationPolicy.isWebsite(uri) && uri.path == '/contacts.php')
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Contact details preview. The contact form is available in the installed app.',
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: EmbeddedPage(
            uri: PreviewDestination.source(uri),
            title: title,
            onNavigate: onNavigate,
          ),
        ),
      ],
    );
  }
}
