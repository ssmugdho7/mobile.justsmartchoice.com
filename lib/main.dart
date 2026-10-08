import 'package:flutter/material.dart';

import 'crm_browser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartChoiceApp());
}

class SmartChoiceApp extends StatelessWidget {
  const SmartChoiceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Choice Mobile',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff107566)),
      scaffoldBackgroundColor: const Color(0xfff4f7f9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xff17453e),
        centerTitle: false,
        elevation: 0,
      ),
    ),
    home: const CrmBrowser(),
  );
}
