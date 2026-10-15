import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'landing menu routes to existing websites and CRM without submissions',
    (tester) async {
      final visits = <Uri>[];
      InAppWebViewController? web;
      await tester.pumpWidget(
        SmartChoiceApp(
          onPageReady: (controller) async {
            web = controller;
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
      await tester.pump(const Duration(milliseconds: 600));
      final menuDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (find.text('Employee Login').evaluate().isEmpty &&
          DateTime.now().isBefore(menuDeadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 600));
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

      Future<void> home({bool shop = false}) async {
        await tester.tap(
          find.byTooltip(shop ? 'Open navigation menu' : 'Open navigation'),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.widgetWithText(ListTile, 'Home'));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Shop'), findsOneWidget);
        visits.clear();
      }

      Future<void> readable() async {
        // Redirects can replace the JavaScript context after an onLoadStop
        // callback. Wait for an actual readable document rather than casting a
        // transient null result to num.
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        num length = 0;
        while (length <= 100 && DateTime.now().isBefore(deadline)) {
          final value = await web!.evaluateJavascript(
            source: 'document.readyState === "complete" && document.body ? document.body.innerText.trim().length : 0',
          );
          length = value is num ? value : 0;
          if (length <= 100) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 250)),
            );
            await tester.pump();
          }
        }
        expect(length, greaterThan(100));
        expect(find.text('Unable to load this page'), findsNothing);
        expect(tester.takeException(), isNull);
      }

      // Native WebViews can keep progress/website animations active; wait for
      // explicit page assertions above rather than all Flutter frames to settle.
      // Work backwards through the six-button menu without submitting records.
      await tester.tap(find.text('Shop'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'crm.justsmartchoice.com' &&
            uri.path == '/products/client',
      );
      await readable();
      final catalogueDeadline = DateTime.now().add(const Duration(seconds: 30));
      var productCount = 0;
      while (productCount == 0 && DateTime.now().isBefore(catalogueDeadline)) {
        final value = await web!.evaluateJavascript(
          source: 'document.querySelectorAll(".sc-product-card").length',
        );
        productCount = value is num ? value.toInt() : 0;
        if (productCount == 0) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)),
          );
          await tester.pump();
        }
      }
      expect(
        productCount,
        greaterThan(0),
        reason: 'The live Shop catalogue must load its products',
      );
      expect(
        await web!.evaluateJavascript(
          source: 'document.body.innerText.includes("Page expired")',
        ),
        false,
      );
      for (final policy in ['/privacy.php', '/terms.php']) {
        visits.clear();
        await web!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('https://justsmartchoice.com$policy'),
          ),
        );
        await waitFor((uri) => uri.path == policy);
        await readable();
      }
      await home(shop: true);

      await tester.tap(find.text('Toolbox'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'justsmartchoice.com' && uri.path == '/toolbox.php',
      );
      final count = await web!.evaluateJavascript(
        source: 'document.querySelectorAll("a.smart-toolbox-box").length',
      );
      expect(count as num, greaterThanOrEqualTo(28));
      await readable();
      await home();

      await tester.tap(find.text('Contact Us'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'justsmartchoice.com' && uri.path == '/contacts.php',
      );
      await readable();
      await home();

      await tester.tap(find.text('Book an Appointment'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'crm.justsmartchoice.com' &&
            uri.path == '/appointly/appointments_public/book',
      );
      await readable();
      final selected = await web!.evaluateJavascript(
        source: 'var service=document.querySelector(".service-card");if(service){service.click();true}else{false}',
      );
      expect(
        selected,
        true,
        reason: 'At least one public booking service should be selectable',
      );
      final providerDeadline = DateTime.now().add(const Duration(seconds: 30));
      var providerCount = 0;
      while (providerCount == 0 && DateTime.now().isBefore(providerDeadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
        providerCount = (await web!.evaluateJavascript(
          source: 'document.querySelectorAll(".provider-card").length',
        ) as num).toInt();
      }
      expect(
        providerCount,
        greaterThan(0),
        reason: 'Provider lookup must work without an expired-page error',
      );
      final expired = await web!.evaluateJavascript(
        source: 'document.body.innerText.includes("Page expired")',
      );
      expect(expired, false);
      await home();

      await tester.tap(find.text('Client Login'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'crm.justsmartchoice.com' &&
            (uri.path.startsWith('/clients') ||
                uri.path.startsWith('/authentication')),
      );
      await readable();
      await home();

      await tester.tap(find.text('Employee Login'));
      await tester.pump();
      await waitFor(
        (uri) =>
            uri.host == 'crm.justsmartchoice.com' &&
            (uri.path.startsWith('/admin') ||
                uri.path.startsWith('/authentication')),
      );
      await readable();
      await home();

      await tester.tap(find.byTooltip('App settings'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.widgetWithText(ListTile, 'About'));
      await tester.pump();
      await waitFor(
        (uri) => uri.host == 'justsmartchoice.com' && uri.path == '/about.php',
      );
      await readable();
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Employee Login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
