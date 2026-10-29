import 'package:flutter/material.dart';

/// Widget-test stand-in; browser builds use the real embedded document.
class EmbeddedPage extends StatelessWidget {
  const EmbeddedPage({
    super.key,
    required this.uri,
    required this.title,
    this.onNavigate,
    this.onLocationChanged,
  });
  final Uri uri;
  final String title;
  final ValueChanged<Uri>? onNavigate;
  final ValueChanged<Uri>? onLocationChanged;
  @override
  Widget build(BuildContext context) =>
      Semantics(label: title, child: Text('Embedded page: $uri'));
}
