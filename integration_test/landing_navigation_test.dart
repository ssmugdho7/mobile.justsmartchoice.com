import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'landing menu routes to existing websites and CRM without submissions',
    (tester) async {
      final visits = <Uri>[];
      await tester.pumpWidget(
        SmartChoiceApp(
          onPageReady: (controller) async {
            final result = await controller.evaluateJavascript(
              source: 'JSON.stringify({host:location.hostname,path:location.pathname})',
            );
            if (result is String) {
              final location = jsonDecode(result) as Map;
              visits.add(
                Uri.https(
                  location['host'] as String,
                  location['path'] as String,
                ),
              );
            }
          },
        ),
      );
      await tester.pumpAndSettle();
      final menuDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (find.text('Employee Login').evaluate().isEmpty &&
          DateTime.now().isBefore(menuDeadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(
        visits,
        isEmpty,
        reason: 'No public website should load behind the first screen',
      );
      for (final label in [
        'Employee Login',
        'Client Login',
        'Book an Appointment',
        'Contact Us',
        'Toolbox',
        'Shop',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      Future<void> waitFor(bool Function(Uri) matches) async {
        final deadline = DateTime.now().add(const Duration(seconds: 45));
        while (!visits.any(matches) && DateTime.now().isBefore(deadline)) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)),
          );
          await tester.pump();
        }
        expect(visits.any(matches), isTrue);
      }

      await tester.tap(find.text('Shop'));
      await tester.pump();
      await waitFor(
        (uri) => uri.host == 'justsmartchoice.com' && uri.path == '/',
      );
      // Use app navigation rather than submitting website/CRM forms.
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Home'));
      await tester.pumpAndSettle();
      visits.clear();
      await tester.tap(find.text('Employee Login'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'crm.justsmartchoice.com' &&
            (uri.path.startsWith('/admin') ||
                uri.path.startsWith('/authentication')),
      );
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Home'));
      await tester.pumpAndSettle();
      expect(find.text('Shop'), findsOneWidget);
      visits.clear();
      await tester.tap(find.text('Contact Us'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'justsmartchoice.com' && uri.path == '/contacts.php',
      );
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Home'));
      await tester.pumpAndSettle();
      expect(find.text('Employee Login'), findsOneWidget);
      visits.clear();
      await tester.tap(find.text('Book an Appointment'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'crm.justsmartchoice.com' &&
            uri.path == '/appointly/appointments_public/book',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
