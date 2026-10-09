import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/portal_surface_web.dart';

void main() {
  testWidgets('browser portal explains native limits and returns home', (
    tester,
  ) async {
    var returned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(
          initialUri: Uri.parse('https://crm.justsmartchoice.com/clients'),
          onHome: () => returned = true,
        ),
      ),
    );
    expect(find.text('Customer portal'), findsNWidgets(2));
    expect(find.textContaining('need native-device testing'), findsOneWidget);
    expect(find.text('Open customer portal in a new tab'), findsOneWidget);
    await tester.tap(find.text('Back to Home'));
    expect(returned, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final destination in {
    'Make appointment':
        'https://crm.justsmartchoice.com/appointly/appointments',
    'Book an Appointment':
        'https://crm.justsmartchoice.com/appointly/appointments_public/book',
    'Toolbox': 'https://justsmartchoice.com/toolbox.php',
  }.entries) {
    testWidgets('${destination.key} preview identifies its destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PortalSurface(initialUri: Uri.parse(destination.value)),
        ),
      );
      expect(find.text(destination.key), findsNWidgets(2));
      expect(find.text('Staff portal'), findsNothing);
    });
  }
}
