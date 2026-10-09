import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'app_shell.dart';
import 'app_theme.dart';

SemanticsHandle? previewSemantics;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  previewSemantics = SemanticsBinding.instance.ensureSemantics();
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Choice Mobile — Design Preview',
    debugShowCheckedModeBanner: false,
    theme: smartChoiceTheme(),
    home: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Mobile preview · Connected to live CRM\nBuild ${String.fromEnvironment('PREVIEW_COMMIT', defaultValue: 'local')} · ${String.fromEnvironment('PREVIEW_DATE', defaultValue: 'development')}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 430),
                  child: AppShell(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
