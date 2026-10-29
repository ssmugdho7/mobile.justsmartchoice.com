import 'package:flutter/material.dart';

import 'portal_navigation.dart';

/// Widget-test stand-in; browser builds use the real embedded document.
class EmbeddedPage extends StatelessWidget {
  const EmbeddedPage({
    super.key,
    required this.uri,
    required this.title,
    this.onNavigate,
    this.onLocationChanged,
    this.navigationRevision = 0,
    this.portalController,
  });
  final Uri uri;
  final String title;
  final ValueChanged<Uri>? onNavigate;
  final ValueChanged<Uri>? onLocationChanged;
  final int navigationRevision;
  final PortalFrameController? portalController;
  @override
  Widget build(BuildContext context) =>
      Semantics(label: title, child: Text('Embedded page: $uri'));
}
