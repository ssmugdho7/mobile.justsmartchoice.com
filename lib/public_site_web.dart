import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web/web.dart' as web;

/// Only public marketing content is copied. CRM sessions never enter this frame.
class PublicSiteView extends StatefulWidget {
  const PublicSiteView({
    super.key,
    required this.uri,
    this.onPageReady,
    this.onBrowserCreated,
  });
  final Uri uri;
  final Future<void> Function(InAppWebViewController)? onPageReady;
  final void Function(InAppWebViewController)? onBrowserCreated;
  @override
  State<PublicSiteView> createState() => _PublicSiteViewState();
}

class _PublicSiteViewState extends State<PublicSiteView> {
  static int _nextId = 0;
  late final String _viewType;
  @override
  void initState() {
    super.initState();
    _viewType = 'smart-choice-public-${_nextId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final page = widget.uri.path == '/about.php' ? 'about' : 'home';
      return web.HTMLIFrameElement()
        ..src = 'public-pages/$page.html'
        ..title =
            'Smart Choice ${page == 'home' ? 'Home' : 'About'} public page preview'
        ..setAttribute(
          'sandbox',
          'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox',
        )
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
