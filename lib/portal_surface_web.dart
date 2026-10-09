import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// Browser design preview never embeds authenticated CRM data or native plugins.
class PortalSurface extends StatelessWidget {
  const PortalSurface({
    super.key,
    this.initialUri,
    this.navigationDrawer,
    this.onAbout,
    this.onHome,
    this.onBrowserCreated,
    this.onPageReady,
    this.handleBack = true,
  });
  final Uri? initialUri;
  final bool handleBack;
  final Widget? navigationDrawer;
  final VoidCallback? onAbout, onHome;
  final void Function(InAppWebViewController)? onBrowserCreated;
  final Future<void> Function(InAppWebViewController)? onPageReady;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Portal preview')),
    drawer: navigationDrawer,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.open_in_new, size: 48, color: Color(0xff107566)),
        const SizedBox(height: 24),
        Text(
          initialUri?.path == '/clients' ? 'Customer portal' : 'Staff portal',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Text(
          'This browser preview shows the app interface. The native app opens your CRM inside its secure browser. Login, document saving, camera uploads and video calls need native-device testing.',
          style: TextStyle(height: 1.7),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => launchUrl(initialUri!, webOnlyWindowName: '_blank'),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open live CRM in a new tab'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_outlined),
          label: const Text('Back to Home'),
        ),
      ],
    ),
  );
}
