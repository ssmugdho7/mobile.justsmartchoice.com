import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/contact_page.dart';
import 'package:smart_choice_mobile/main.dart';

void main() {
  testWidgets(
    'Contact opens local details and returns Home without a website',
    (tester) async {
      await tester.pumpWidget(
        SmartChoiceApp(
          publicPageBuilder: (_) => throw StateError('Unexpected website'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contact Us'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactPage), findsOneWidget);
      expect(find.text('+1 7277553786'), findsOneWidget);
      expect(find.text('admin@justsmartchoice.com'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('Quick links'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Employee Login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Contact links open the corrected dialer and email destinations',
    (tester) async {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final urls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        urls.add((call.arguments as Map)['url'] as String);
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContactPage())),
      );
      await tester.tap(find.text('+1 7277553786'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('admin@justsmartchoice.com'));
      await tester.pumpAndSettle();
      expect(urls, ['tel:+17277553786', 'mailto:admin@justsmartchoice.com']);
    },
  );

  testWidgets('Contact details fit a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: ContactPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+1 7277553786'), findsOneWidget);
    expect(find.text('admin@justsmartchoice.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
