import 'package:flutter/material.dart';

/// Widget-test stand-in; browser builds use the real embedded document.
class EmbeddedPage extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      Semantics(label: title, child: Text('Embedded page: $uri'));
}
