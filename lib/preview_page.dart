import 'package:flutter/material.dart';

import 'embedded_page.dart';
import 'navigation_policy.dart';
import 'preview_destination.dart';

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
    if (PreviewDestination.missingTools.contains(uri.path) &&
        NavigationPolicy.isWebsite(uri)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 40),
              const SizedBox(height: 16),
              Text(
                'This tool is currently unavailable',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'The original website returns a missing-page error for this calculator. You can continue using the other tools.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => onNavigate(
                  Uri.parse('https://justsmartchoice.com/toolbox.php'),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Toolbox'),
              ),
            ],
          ),
        ),
      );
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
