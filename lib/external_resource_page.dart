import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation_policy.dart';
import 'toolbox_resource.dart';

/// Browser preview handoff only. Native WebViews keep loading these sites in-app.
class ExternalResourcePage extends StatelessWidget {
  const ExternalResourcePage({
    super.key,
    required this.uri,
    required this.onBack,
    this.openWebsite,
  });
  final Uri uri;
  final VoidCallback onBack;
  final Future<bool> Function(Uri)? openWebsite;

  @override
  Widget build(BuildContext context) {
    final resource = ToolboxResource.find(uri);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser, size: 44),
            const SizedBox(height: 16),
            Text(
              resource?.title ?? uri.host,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (resource != null) ...[
              const SizedBox(height: 12),
              Text(resource.description, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            const Text(
              'This resource belongs to an external provider. Open its website to use it; provider restrictions can prevent embedded previews.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(uri.host, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                if (!NavigationPolicy.isHttps(uri)) return;
                var opened = false;
                try {
                  opened =
                      await (openWebsite?.call(uri) ??
                          launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                            webOnlyWindowName: '_blank',
                          ));
                } catch (_) {
                  // Browser popup policies can reject an otherwise valid handoff.
                }
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'The provider website could not be opened. Please try again.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open provider website'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Toolbox'),
            ),
          ],
        ),
      ),
    );
  }
}
