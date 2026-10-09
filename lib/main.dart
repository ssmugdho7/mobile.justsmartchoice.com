import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'crm_browser.dart';
import 'app_shell.dart';
import 'app_theme.dart';
import 'startup_permissions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SmartChoiceApp(afterIntro: StartupPermissions.initialize));
}

class SmartChoiceApp extends StatelessWidget {
  const SmartChoiceApp({
    super.key,
    this.onPageReady,
    this.initialUri,
    this.startInPortal = false,
    this.publicPageBuilder,
    this.afterIntro,
  });
  final Future<void> Function()? afterIntro;
  final Uri? initialUri;
  final bool startInPortal;
  final Widget Function(Uri)? publicPageBuilder;
  final Future<void> Function(InAppWebViewController)? onPageReady;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Choice Mobile',
    debugShowCheckedModeBanner: false,
    theme: smartChoiceTheme(),
    home: startInPortal
        ? CrmBrowser(onPageReady: onPageReady, initialUri: initialUri)
        : AppShell(
            afterIntro: afterIntro,
            onPageReady: onPageReady,
            publicPageBuilder: publicPageBuilder,
          ),
  );
}
