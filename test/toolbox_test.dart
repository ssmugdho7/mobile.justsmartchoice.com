import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/external_resource_page.dart';
import 'package:smart_choice_mobile/preview_destination.dart';
import 'package:smart_choice_mobile/toolbox_navigation.dart';
import 'package:smart_choice_mobile/toolbox_unavailable.dart';

void main() {
  test(
    'Calculator routes resolve on our website only and preserve URL details',
    () {
      for (final name in ToolboxNavigation.calculatorNames) {
        final root = Uri.parse(
          'https://justsmartchoice.com/$name?mode=1#results',
        );
        final resolved = ToolboxNavigation.resolve(root);
        expect(resolved.path, '/calculators/$name');
        expect(resolved.query, 'mode=1');
        expect(resolved.fragment, 'results');
        expect(ToolboxNavigation.resolve(resolved), resolved);
        final external = Uri.parse('https://example.com/$name');
        expect(ToolboxNavigation.resolve(external), external);
        expect(
          PreviewDestination.source(root),
          PreviewDestination.source(resolved),
        );
      }
      expect(
        PreviewDestination.source(
          Uri.parse(
            'https://justsmartchoice.com/forms.php#notice-of-commencement',
          ),
        ).fragment,
        'notice-of-commencement',
      );
    },
  );
  test('Missing public files recover without blocking unrelated documents', () {
    for (final path in ToolboxNavigation.missingResources) {
      expect(
        ToolboxNavigation.isMissingResource(
          Uri.parse('https://justsmartchoice.com$path'),
        ),
        true,
      );
      expect(
        ToolboxNavigation.isMissingResource(
          Uri.parse('https://crm.justsmartchoice.com$path'),
        ),
        false,
      );
    }
    expect(
      ToolboxNavigation.isMissingResource(
        Uri.parse('https://justsmartchoice.com/forms/new.pdf'),
      ),
      false,
    );
    expect(
      PreviewDestination.source(
        Uri.parse('https://justsmartchoice.com/notice-of-commencement.php'),
      ).fragment,
      'notice-of-commencement',
    );
  });
  testWidgets(
    'Provider opens only after explicit click and Back remains available',
    (tester) async {
      final uri = Uri.parse('https://www.progressivecommercial.com/');
      final opened = <Uri>[];
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExternalResourcePage(
              uri: uri,
              onBack: () => returned = true,
              openWebsite: (uri) async {
                opened.add(uri);
                return true;
              },
            ),
          ),
        ),
      );
      expect(opened, isEmpty);
      await tester.tap(find.text('Open provider website'));
      await tester.pumpAndSettle();
      expect(opened, [uri]);
      await tester.tap(find.text('Back to Toolbox'));
      expect(returned, isTrue);
    },
  );
  testWidgets('Popup rejection has a recoverable message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExternalResourcePage(
            uri: Uri.parse('https://www.progressivecommercial.com/'),
            onBack: () {},
            openWebsite: (_) async => throw StateError('blocked'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open provider website'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be opened'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Missing agreement offers Forms Library without substituting a document',
    (tester) async {
      Uri? target;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolboxUnavailable(onNavigate: (uri) => target = uri),
          ),
        ),
      );
      await tester.tap(find.text('View Forms Library'));
      expect(target.toString(), 'https://justsmartchoice.com/forms.php');
    },
  );
}
