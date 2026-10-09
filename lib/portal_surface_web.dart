import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'preview_page.dart';
import 'preview_navigation.dart';
import 'navigation_policy.dart';
import 'quick_links.dart';

/// Render the actual CRM inside the mobile frame. Marketing pages use public
/// snapshots; authenticated responses and credentials are never copied.
class PortalSurface extends StatefulWidget {
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
  State<PortalSurface> createState() => _PortalSurfaceState();
}

class _PortalSurfaceState extends State<PortalSurface> {
  late Uri _uri = widget.initialUri ?? NavigationPolicy.home;
  int _reload = 0;
  @override
  void didUpdateWidget(PortalSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUri != oldWidget.initialUri) {
      _uri = widget.initialUri ?? NavigationPolicy.home;
    }
  }

  void _navigate(Uri uri) =>
      followPreviewLink(uri, (next) => setState(() => _uri = next));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(QuickLink.labelFor(_uri)),
      leading: IconButton(
        tooltip: 'Back to Home',
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onHome,
      ),
      actions: [
        IconButton(
          tooltip: 'Reload page',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => _reload++),
        ),
        QuickLinksMenu(
          onSelected: (link) => _navigate(link.uri),
          onAbout: widget.onAbout,
        ),
      ],
    ),
    drawer: widget.navigationDrawer,
    body: PreviewPage(
      key: ValueKey(_reload),
      uri: _uri,
      title: QuickLink.labelFor(_uri),
      onNavigate: _navigate,
    ),
  );
}
