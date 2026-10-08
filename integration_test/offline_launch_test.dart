import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/main.dart';

// Run this smoke test only while mobile.justsmartchoice.com is unavailable.
// It exercises the actual native WebView DNS failure, not a mocked widget.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Unconfigured mobile site shows retry on Android', (
    tester,
  ) async {
    final screenshotKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: screenshotKey, child: const SmartChoiceApp()),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (find.text('Unable to connect').evaluate().isEmpty &&
        DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
    }
    expect(find.text('Unable to connect'), findsOneWidget);
    expect(find.text('mobile.justsmartchoice.com'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    await tester.pump();
    final boundary =
        screenshotKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary
        .toImage(pixelRatio: 2)
        .timeout(const Duration(seconds: 15));
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    binding.reportData = {
      'screenshotPng': base64Encode(png!.buffer.asUint8List()),
    };
    image.dispose();
  });
}
