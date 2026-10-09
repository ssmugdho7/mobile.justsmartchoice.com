import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'navigation_policy.dart';

class EmbeddedPage extends StatefulWidget {
  const EmbeddedPage({
    super.key,
    required this.uri,
    required this.title,
    this.onNavigate,
  });
  final Uri uri;
  final String title;
  final ValueChanged<Uri>? onNavigate;
  @override
  State<EmbeddedPage> createState() => _EmbeddedPageState();
}

class _EmbeddedPageState extends State<EmbeddedPage> {
  static int _nextId = 0;
  late final String _viewType;
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;
  @override
  void initState() {
    super.initState();
    _viewType = 'smart-choice-inline-${_nextId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final frame = web.HTMLIFrameElement()
        ..src = widget.uri.toString()
        ..title = widget.title
        // No popups or top navigation: links cannot eject the mobile interface.
        // CRM retains its own HTTPS, sessions, CAPTCHA, CSRF and permissions.
        ..setAttribute(
          'sandbox',
          'allow-scripts allow-same-origin allow-forms allow-downloads',
        )
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      _frame = frame;
      return frame;
    });
    _listener = ((web.MessageEvent event) {
      if (_frame == null || event.source != _frame!.contentWindow) return;
      // Only copied public pages send navigation messages. The authenticated
      // CRM frame is never read, proxied or copied by this interface.
      final expected = Uri.parse(web.document.baseURI)
          .resolve(widget.uri.toString())
          .origin;
      if (event.origin != expected) return;
      final data = event.data.dartify();
      if (data is! Map ||
          data['type'] != 'sc-mobile-navigate' ||
          data['url'] is! String) {
        return;
      }
      final uri = Uri.tryParse(data['url'] as String);
      if (uri != null &&
          NavigationPolicy.decide(uri) != NavigationDecision.blocked) {
        widget.onNavigate?.call(uri);
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void didUpdateWidget(EmbeddedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) _frame?.src = widget.uri.toString();
    if (oldWidget.title != widget.title) _frame?.title = widget.title;
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    _frame?.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
