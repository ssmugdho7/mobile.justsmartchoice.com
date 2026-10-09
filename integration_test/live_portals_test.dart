import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Live staff and customer portals keep server authentication', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    final observations = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: SmartChoiceApp(
          startInPortal: true,
          onPageReady: (controller) async {
            final result = await controller.evaluateJavascript(
              source: '''JSON.stringify({
          host: location.hostname, path: location.pathname,
          login: !!document.querySelector('input[type="password"]'),
          staff: !!document.querySelector('#side-menu'),
          customer: !!document.querySelector('.navbar.header'),
          csrf: !!document.querySelector('input[name*="csrf"]'),
          passwordToggle: !!document.querySelector('.sc-auth-password button'),
          remember: document.querySelector('#remember')?.value === '1'
        })''',
            );
            if (result is String) {
              observations.add(
                Map<String, dynamic>.from(jsonDecode(result) as Map),
              );
            }
          },
        ),
      ),
    );
    Future<void> waitFor(bool Function() ready) async {
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
      }
      expect(ready(), isTrue, reason: 'Live CRM portal did not finish loading');
    }

    await waitFor(
      () => observations.any(
        (r) =>
            r['host'] == 'crm.justsmartchoice.com' &&
            (r['login'] == true || r['staff'] == true),
      ),
    );
    final staff = observations.last;
    if (staff['login'] == true) {
      expect(staff['csrf'], isTrue);
      expect(staff['passwordToggle'], isTrue);
      expect(staff['remember'], isTrue);
    }
    await tester.pump();
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    binding.reportData = {
      'screenshotPng': base64Encode(png!.buffer.asUint8List()),
    };
    image.dispose();
    observations.clear();
    await tester.tap(find.byTooltip('Quick links'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer portal'));
    await tester.pump();
    await waitFor(
      () => observations.any(
        (r) =>
            r['host'] == 'crm.justsmartchoice.com' &&
            (r['login'] == true || r['customer'] == true),
      ),
    );
    expect(
      observations.every((r) => r['host'] == 'crm.justsmartchoice.com'),
      isTrue,
    );
    if (observations.last['login'] == true) {
      expect(observations.last['passwordToggle'], isTrue);
      expect(observations.last['remember'], isTrue);
    }
  });
}
