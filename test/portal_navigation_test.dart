import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/embedded_page.dart';
import 'package:smart_choice_mobile/portal_navigation.dart';
import 'package:smart_choice_mobile/portal_surface_web.dart';

void main() {
  final dashboard = Uri.parse('https://crm.justsmartchoice.com/admin');
  final todo = dashboard.resolve('/admin/todo');
  test(
    'canonical dashboard and back navigation do not create phantom history',
    () {
      final history = PortalHistory(dashboard);
      history.visit(dashboard.replace(path: '/admin/'));
      expect(history.previous, isNull);
      history.visit(todo);
      expect(history.previous, dashboard);
      history.visit(dashboard);
      expect(history.previous, isNull);
    },
  );
  testWidgets('Back from a staff child page stays inside the portal', (
    tester,
  ) async {
    var exited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(initialUri: dashboard, onHome: () => exited = true),
      ),
    );
    var frame = tester.widget<EmbeddedPage>(find.byType(EmbeddedPage));
    frame.onLocationChanged!(dashboard);
    frame.onLocationChanged!(todo);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    frame = tester.widget<EmbeddedPage>(find.byType(EmbeddedPage));
    expect(frame.uri.path, '/admin');
    expect(exited, false);
    expect(find.text('Leave this portal?'), findsNothing);
  });
  testWidgets('Leaving portal requires confirmation and Stay cancels it', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(initialUri: dashboard, onHome: () => exits++),
      ),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Leave this portal?'), findsOneWidget);
    expect(exits, 0);
    await tester.tap(find.text('Stay here'));
    await tester.pumpAndSettle();
    expect(exits, 0);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave portal'));
    await tester.pumpAndSettle();
    expect(exits, 1);
  });
  testWidgets('Initial authentication redirect is not a second history entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PortalSurface(initialUri: dashboard, onHome: () {}),
      ),
    );
    tester.widget<EmbeddedPage>(find.byType(EmbeddedPage)).onLocationChanged!(
      dashboard.resolve('/admin/authentication'),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Leave this portal?'), findsOneWidget);
  });
}
