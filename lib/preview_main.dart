import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'app_shell.dart';
import 'app_theme.dart';

SemanticsHandle? previewSemantics;

// This preview uses in-app state, not URL routes. Older cached hosting wrappers
// must not make Flutter rewrite history against their remote asset base.
void main() {
  ui_web.urlStrategy = null;
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final framed = constraints.maxWidth >= 600;
            return Center(
              child: Padding(
                padding: EdgeInsets.all(framed ? 16 : 0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 430,
                    maxHeight: framed ? 900 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      if (framed)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Mobile preview · Connected to live CRM\nBuild ${String.fromEnvironment('PREVIEW_COMMIT', defaultValue: 'local')} · ${String.fromEnvironment('PREVIEW_DATE', defaultValue: 'development')}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, height: 1.5),
                          ),
                        ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(framed ? 24 : 0),
                          child: const AppShell(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
