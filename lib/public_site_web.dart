import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'preview_page.dart';
import 'preview_navigation.dart';

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
  late Uri _uri = widget.uri;
  @override
  Widget build(BuildContext context) => PreviewPage(
    uri: _uri,
    title: 'Smart Choice public page',
    onNavigate: (uri) =>
        followPreviewLink(uri, (next) => setState(() => _uri = next)),
  );
}
