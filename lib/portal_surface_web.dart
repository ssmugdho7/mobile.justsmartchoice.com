import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'preview_page.dart';
import 'preview_navigation.dart';
import 'navigation_policy.dart';
import 'quick_links.dart';
import 'portal_navigation.dart';

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
  late PortalHistory _history = PortalHistory(_uri);
  int _reload = 0;
  bool _leaving = false;
  bool _reportedLocation = false;
  @override
  void didUpdateWidget(PortalSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUri != oldWidget.initialUri ||
        (!oldWidget.handleBack && widget.handleBack)) {
      _uri = widget.initialUri ?? NavigationPolicy.home;
      _history = PortalHistory(_uri);
      _reportedLocation = false;
      // Reopening a destination from Home must start at its requested page,
      // even after the cross-origin CRM frame navigated internally.
      _reload++;
    }
  }

  Future<void> _navigate(Uri uri) async {
    if (isUserPortal(_history.current) &&
        !isUserPortal(uri) &&
        !await confirmLeavePortal(context)) {
      return;
    }
    await followPreviewLink(
      uri,
      (next) => setState(() {
        _history.visit(next);
        _uri = next;
      }),
      onUnavailable: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No app can open this link.')),
          );
        }
      },
    );
  }

  Future<void> _back() async {
    if (_leaving) return;
    final previous = _history.previous;
    if (previous != null) {
      if (isUserPortal(_history.current) &&
          !isUserPortal(previous) &&
          !await confirmLeavePortal(context)) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _history.visit(previous);
        _uri = previous;
      });
      return;
    }
    await _leave(widget.onHome);
  }

  Future<void> _leave(VoidCallback? action) async {
    if (_leaving || action == null) return;
    _leaving = true;
    try {
      if (!isUserPortal(_history.current) ||
          await confirmLeavePortal(context)) {
        if (mounted) action();
      }
    } finally {
      _leaving = false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.handleBack,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && widget.handleBack) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(QuickLink.labelFor(_uri)),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        actions: [
          IconButton(
            tooltip: 'Reload page',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _reload++),
          ),
          QuickLinksMenu(
            onSelected: (link) => _navigate(link.uri),
            onAbout: widget.onAbout == null
                ? null
                : () => _leave(widget.onAbout),
          ),
        ],
      ),
      drawer: widget.navigationDrawer,
      body: PreviewPage(
        key: ValueKey(_reload),
        uri: _uri,
        title: QuickLink.labelFor(_uri),
        onNavigate: _navigate,
        onLocationChanged: (uri) {
          if (!_reportedLocation) {
            _history = PortalHistory(uri);
            _reportedLocation = true;
          } else {
            _history.visit(uri);
          }
        },
      ),
    ),
  );
}
