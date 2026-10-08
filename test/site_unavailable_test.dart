import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/site_unavailable.dart';

void main() {
  testWidgets('Missing mobile site offers retry without production fallback', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SiteUnavailable(onRetry: () => retried = true)),
      ),
    );
    expect(find.text('Unable to connect'), findsOneWidget);
    expect(find.text('mobile.justsmartchoice.com'), findsOneWidget);
    expect(find.textContaining('crm.justsmartchoice.com'), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Error feedback fits narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(body: SiteUnavailable(onRetry: () {}, httpError: true)),
      ),
    );
    expect(find.text('This page is unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
