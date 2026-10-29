import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'preview_page.dart';
import 'preview_navigation.dart';
import 'portal_navigation.dart';

class PublicSiteView extends StatefulWidget {
  const PublicSiteView({
    super.key,
    required this.uri,
    this.onPageReady,
    this.onBrowserCreated,
    this.backController,
    this.onLocationChanged,
  });
  final Uri uri;
  final Future<void> Function(InAppWebViewController)? onPageReady;
  final void Function(InAppWebViewController)? onBrowserCreated;
  final PortalBackController? backController;
  final ValueChanged<Uri>? onLocationChanged;
  @override
  State<PublicSiteView> createState() => _PublicSiteViewState();
}

class _PublicSiteViewState extends State<PublicSiteView> {
  late Uri _uri = widget.uri;
  late PortalHistory _history = PortalHistory(_uri);
  bool _reportedLocation = false;
  int _navigationRevision = 0;
  final _frameController = PortalFrameController();
  @override
  void initState() {
    super.initState();
    widget.backController?.onBack = () async {
      if (_frameController.overlayOpen) {
        _frameController.closeOverlay?.call();
        return true;
      }
      final previous = _history.previous;
      if (previous == null) return false;
      if (isUserPortal(_history.current) &&
          !isUserPortal(previous) &&
          !await confirmLeavePortal(context)) {
        return true;
      }
      if (!mounted) return true;
      setState(() {
        _navigationRevision++;
        _history.visit(previous);
        _uri = previous;
      });
      return true;
    };
  }

  @override
  void dispose() {
    widget.backController?.onBack = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PreviewPage(
    uri: _uri,
    title: 'Smart Choice public page',
    navigationRevision: _navigationRevision,
    portalController: _frameController,
    onLocationChanged: (uri) {
      if (!_reportedLocation) {
        _history = PortalHistory(uri);
        _reportedLocation = true;
      } else {
        _history.visit(uri);
      }
      widget.onLocationChanged?.call(uri);
    },
    onNavigate: (uri) => followPreviewLink(
      uri,
      (next) => setState(() {
        _navigationRevision++;
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
    ),
  );
}
