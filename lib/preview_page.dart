import 'package:flutter/material.dart';

import 'embedded_page.dart';
import 'navigation_policy.dart';
import 'preview_destination.dart';
import 'external_resource_page.dart';
import 'toolbox_unavailable.dart';
import 'contact_page.dart';

/// Live CRM pages retain their own authentication. Public website snapshots
/// avoid weakening the website's frame restrictions for the browser preview.
class PreviewPage extends StatelessWidget {
  const PreviewPage({
    super.key,
    required this.uri,
    required this.title,
    required this.onNavigate,
    this.onLocationChanged,
  });
  final Uri uri;
  final String title;
  final ValueChanged<Uri> onNavigate;
  final ValueChanged<Uri>? onLocationChanged;

  @override
  Widget build(BuildContext context) {
    if (NavigationPolicy.isWebsite(uri) && uri.path == '/contacts.php') {
      return const ContactPage();
    }
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
    if (NavigationPolicy.isWebsite(uri) &&
        !PreviewDestination.hasPublicPreview(uri)) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.web_asset_off_outlined, size: 44),
              const SizedBox(height: 16),
              Text(
                'This page is not available in the browser preview',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'You can return to Shop and continue exploring the available preview pages here.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => onNavigate(NavigationPolicy.shop),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Back to Shop'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: EmbeddedPage(
            uri: PreviewDestination.source(uri),
            title: title,
            onNavigate: onNavigate,
            onLocationChanged: onLocationChanged,
          ),
        ),
      ],
    );
  }
}
