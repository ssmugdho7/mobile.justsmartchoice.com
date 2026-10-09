import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/main.dart';

// Pass an authorized existing proposal URL at runtime, never commit a private
// document hash or session cookie. This test only downloads; it never approves,
// signs, pays, sends or changes the proposal.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const proposalUrl = String.fromEnvironment('TEST_PROPOSAL_URL');
  testWidgets(
    'Existing proposal POST PDF saves through native Android MediaStore',
    (tester) async {
      var attempted = false;
      await tester.pumpWidget(
        SmartChoiceApp(
          startInPortal: true,
          initialUri: Uri.parse(proposalUrl),
          onPageReady: (controller) async {
            if (attempted) return;
            final hasPdf = await controller.evaluateJavascript(
              source: "!!document.querySelector('input[name=action][value=proposal_pdf]')",
            );
            if (hasPdf != true) return;
            attempted = true;
            await controller.evaluateJavascript(
              source: """
          const form = document.querySelector('input[name=action][value=proposal_pdf]').form;
          form.requestSubmit(form.querySelector('button[type=submit]'));
        """,
            );
          },
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (find.textContaining('saved to Downloads').evaluate().isEmpty &&
          find.textContaining('Unable to download').evaluate().isEmpty &&
          DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
      }
      expect(attempted, isTrue);
      expect(find.textContaining('saved to Downloads'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.textContaining('Unable to download'), findsNothing);
    },
    skip: proposalUrl.isEmpty,
  );
}
