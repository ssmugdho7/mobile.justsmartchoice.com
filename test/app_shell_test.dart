import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/main.dart';

Widget publicPage(Uri uri) => Text('Public page: $uri');

void main() {
  testWidgets('Home, valid About, Dark Mode and CRM access remain reachable', (
    tester,
  ) async {
    await tester.pumpWidget(SmartChoiceApp(publicPageBuilder: publicPage));
    await tester.pumpAndSettle();
    expect(find.text('Smart Choice USA'), findsOneWidget);
    expect(
      find.text('Public page: https://justsmartchoice.com/'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.widgetWithText(ListTile, 'About'));
    await tester.pumpAndSettle();
    expect(
      find.text('Public page: https://justsmartchoice.com/about.php'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();
    expect(
      find.text('Public page: https://justsmartchoice.com/'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Quick links'));
    await tester.pumpAndSettle();
    expect(find.text('Staff portal'), findsOneWidget);
    expect(find.text('Customer portal'), findsOneWidget);
    expect(find.text('Call office'), findsOneWidget);
    expect(find.text('Make appointment'), findsOneWidget);
    expect(find.text('Toolbox'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'navigation remains readable on a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(SmartChoiceApp(publicPageBuilder: publicPage));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(ListTile, 'About'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
