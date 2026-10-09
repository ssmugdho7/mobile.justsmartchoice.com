import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'crm_browser.dart';

class PublicSiteView extends StatelessWidget {
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
  Widget build(BuildContext context) => CrmBrowser(
    initialUri: uri,
    showAppBar: false,
    handleBack: false,
    onPageReady: onPageReady,
    onBrowserCreated: onBrowserCreated,
  );
}
