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
    expect(find.text('Customer portal'), findsOneWidget);
    expect(find.textContaining('need native-device testing'), findsOneWidget);
    expect(find.text('Open live CRM in a new tab'), findsOneWidget);
    await tester.tap(find.text('Back to Home'));
    expect(returned, isTrue);
    expect(tester.takeException(), isNull);
  });
}
