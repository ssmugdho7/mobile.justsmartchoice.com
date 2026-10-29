import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/embedded_page.dart';
import 'package:smart_choice_mobile/portal_surface_web.dart';
import 'package:smart_choice_mobile/preview_page.dart';
import 'package:smart_choice_mobile/preview_destination.dart';
import 'package:smart_choice_mobile/quick_links.dart';
import 'package:smart_choice_mobile/preview_navigation.dart';
import 'package:smart_choice_mobile/contact_page.dart';

void main() {
  test(
    'missing phone/email handlers recover without asynchronous errors',
    () async {
      var failures = 0;
      final internals = <Uri>[];
      await followPreviewLink(
        Uri.parse('tel:+17277553786'),
        internals.add,
        onUnavailable: () => failures++,
        launchDevice: (_) async => false,
      );
      await followPreviewLink(
        Uri.parse('mailto:support@example.com'),
        internals.add,
        onUnavailable: () => failures++,
        launchDevice: (_) async => throw StateError('no handler'),
      );
      expect(failures, 2);
      expect(internals, isEmpty);
      await followPreviewLink(
        Uri.parse('https://crm.justsmartchoice.com/admin'),
        internals.add,
        launchDevice: (_) async => throw StateError('must stay internal'),
      );
      expect(internals.single.host, 'crm.justsmartchoice.com');
    },
  );

  testWidgets('Shop remains the live CRM product page inside the preview', (
    tester,
  ) async {
    final uri = Uri.parse('https://crm.justsmartchoice.com/products/client');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreviewPage(uri: uri, title: 'Shop', onNavigate: (_) {}),
        ),
      ),
    );
    expect(tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri, uri);
  });

  test('appointment quick links open the public booking form', () {
    expect(
      QuickLink.appointment.uri.toString(),
      'https://crm.justsmartchoice.com/appointly/appointments_public/book',
    );
  });

  for (final page in [
    'terms',
    'privacy',
    'cookie-policy',
    'legal',
    'sitemap',
    'partners',
    'investors',
    'services',
    'financing',
    'blog',
    'faqs',
    'career',
    'promo_flooring',
    'charger',
    'login',
  ]) {
    testWidgets('$page stays in a bundled public preview', (tester) async {
      final uri = Uri.parse('https://justsmartchoice.com/$page.php');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreviewPage(uri: uri, title: page, onNavigate: (_) {}),
          ),
        ),
      );
      expect(PreviewDestination.hasPublicPreview(uri), isTrue);
      expect(
        tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri.path,
        'public-pages/$page.html',
      );
    });
  }

  testWidgets('unbundled website pages recover inside the preview', (
    tester,
  ) async {
    Uri? target;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreviewPage(
            uri: Uri.parse('https://justsmartchoice.com/unknown-page.php'),
            title: 'Unknown public page',
            onNavigate: (uri) => target = uri,
          ),
        ),
      ),
    );
    expect(find.byType(EmbeddedPage), findsNothing);
    expect(
      find.text('This page is not available in the browser preview'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to Shop'));
    expect(
      target.toString(),
      'https://crm.justsmartchoice.com/products/client',
    );
  });

  testWidgets('appointment in the quick menu opens the same public form', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(
          initialUri: Uri.parse('https://justsmartchoice.com/toolbox.php'),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Quick links'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make appointment'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri.toString(),
      'https://crm.justsmartchoice.com/appointly/appointments_public/book',
    );
  });

  testWidgets(
    'customer portal renders inline and confirms before returning Home',
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
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(returned, isFalse);
      await tester.tap(find.text('Leave portal'));
      await tester.pumpAndSettle();
      expect(returned, isTrue);
    },
  );
  testWidgets('reopening a portal from Home reloads its starting page', (
    tester,
  ) async {
    final booking = Uri.parse(
      'https://crm.justsmartchoice.com/appointly/appointments_public/book',
    );
    Widget shell(bool active) => MaterialApp(
      home: PortalSurface(initialUri: booking, handleBack: active),
    );
    await tester.pumpWidget(shell(true));
    final firstFrame = tester.element(find.byType(EmbeddedPage));
    await tester.pumpWidget(shell(false));
    await tester.pumpWidget(shell(true));
    expect(tester.element(find.byType(EmbeddedPage)), isNot(same(firstFrame)));
    expect(tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).uri, booking);
  });

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
  testWidgets('missing agreement stays inside the preview with recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(
          initialUri: Uri.parse(
            'https://justsmartchoice.com/subcontractor-agreement.php',
          ),
        ),
      ),
    );
    expect(find.text('This resource is currently unavailable'), findsOneWidget);
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
  testWidgets(
    'Contact preview shows local details without an embedded website',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PortalSurface(
            initialUri: Uri.parse('https://justsmartchoice.com/contacts.php'),
          ),
        ),
      );
      expect(find.byType(ContactPage), findsOneWidget);
      expect(find.byType(EmbeddedPage), findsNothing);
      expect(find.text('+1 7277553786'), findsOneWidget);
      expect(find.text('admin@justsmartchoice.com'), findsOneWidget);
    },
  );
}
