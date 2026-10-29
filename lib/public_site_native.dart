import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'crm_browser.dart';
import 'portal_navigation.dart';

class PublicSiteView extends StatelessWidget {
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
  Widget build(BuildContext context) => CrmBrowser(
    initialUri: uri,
    showAppBar: false,
    handleBack: false,
    onPageReady: onPageReady,
    onBrowserCreated: onBrowserCreated,
    onLocationChanged: onLocationChanged,
  );
}
