import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/embedded_page.dart';
import 'package:smart_choice_mobile/portal_surface_web.dart';

void main() {
  testWidgets(
    'customer portal renders inline and returns Home without an external CTA',
    (tester) async {
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PortalSurface(
            initialUri: Uri.parse('https://crm.justsmartchoice.com/clients'),
            onHome: () => returned = true,
          ),
        ),
      );
      expect(find.textContaining('new tab'), findsNothing);
      expect(
        tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri.toString(),
        'https://crm.justsmartchoice.com/clients',
      );
      await tester.tap(find.byTooltip('Back to Home'));
      expect(returned, isTrue);
    },
  );
  testWidgets('changing portal destination updates the inline page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(
          initialUri: Uri.parse('https://crm.justsmartchoice.com/admin'),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Quick links'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer portal'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri.toString(),
      'https://crm.justsmartchoice.com/clients',
    );
    expect(find.textContaining('new tab'), findsNothing);
  });
  testWidgets('missing source calculator stays inside the preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(
          initialUri: Uri.parse('https://justsmartchoice.com/calculator.php'),
        ),
      ),
    );
    expect(find.text('This tool is currently unavailable'), findsOneWidget);
    await tester.tap(find.text('Back to Toolbox'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri.path,
      'public-pages/toolbox.html',
    );
  });
  for (final destination in {
    'Book an Appointment': (
      'https://crm.justsmartchoice.com/appointly/appointments_public/book',
      'https://crm.justsmartchoice.com/appointly/appointments_public/book',
    ),
    'Contact Us': (
      'https://justsmartchoice.com/contacts.php',
      'public-pages/contact.html?v=local',
    ),
    'Toolbox': (
      'https://justsmartchoice.com/toolbox.php',
      'public-pages/toolbox.html?v=local',
    ),
  }.entries) {
    testWidgets('${destination.key} opens an inline destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PortalSurface(initialUri: Uri.parse(destination.value.$1)),
        ),
      );
      expect(
        tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri.toString(),
        destination.value.$2,
      );
      expect(find.textContaining('new tab'), findsNothing);
    });
  }
}
