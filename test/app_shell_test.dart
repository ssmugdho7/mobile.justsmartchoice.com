import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:smart_choice_mobile/main.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['SC_CAPTURE_UI'] != '1') return;
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ??
        '${Platform.environment['HOME']}/Development/flutter';
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final bytes = await File(
        '$sdk/bin/cache/artifacts/material_fonts/${entry.value}',
      ).readAsBytes();
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  testWidgets(
    'Home and About navigation works before CRM login or WebView load',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: boundaryKey, child: const SmartChoiceApp()),
      );
      Future<void> capture(String name) async {
        if (Platform.environment['SC_CAPTURE_UI'] != '1') return;
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('dist/screenshots').create(recursive: true);
        await File('dist/screenshots/$name.png')
            .writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      }

      await tester.pumpAndSettle();
      expect(find.text('Welcome to Smart Choice'), findsOneWidget);
      expect(find.text('Open staff portal'), findsOneWidget);
      expect(find.text('Open customer portal'), findsOneWidget);
      expect(find.byType(InAppWebView), findsNothing);
      await tester.runAsync(() => capture('home'));
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'About'));
      await tester.pumpAndSettle();
      expect(
        find.text('Version 0.3.0 · Android testing build'),
        findsOneWidget,
      );
      expect(find.byType(InAppWebView), findsNothing);
      await tester.runAsync(() => capture('about'));
      await tester.ensureVisible(find.text('Back to Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Smart Choice'), findsOneWidget);
    },
  );
  testWidgets(
    'Home and About remain readable on a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const SmartChoiceApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'About'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
