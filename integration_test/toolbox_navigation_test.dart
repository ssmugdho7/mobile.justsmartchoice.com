import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/crm_browser.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native Toolbox resolves calculators, stays in-app, and recovers missing agreements',
    (tester) async {
      InAppWebViewController? web;
      var loaded = '';
      await tester.pumpWidget(
        MaterialApp(
          home: CrmBrowser(
            initialUri: Uri.parse('https://justsmartchoice.com/calculator.php'),
            onBrowserCreated: (controller) => web = controller,
            onPageReady: (controller) async {
              loaded = (await controller.getUrl()).toString();
            },
          ),
        ),
      );
      Future<void> waitFor(bool Function() ready) async {
        final end = DateTime.now().add(const Duration(seconds: 45));
        while (!ready() && DateTime.now().isBefore(end)) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)),
          );
          await tester.pump();
        }
        expect(ready(), isTrue, reason: loaded);
      }

      await waitFor(() => loaded.contains('/calculators/calculator.php'));
      final raw = await web!.evaluateJavascript(
        source: "document.getElementById('display').value='2+3';calculate();JSON.stringify({answer:document.getElementById('display').value,preloader:!!document.querySelector('.preloader'),css:[...document.querySelectorAll('link[rel=stylesheet]')].map(x=>x.getAttribute('href'))})",
      );
      final result = jsonDecode(raw as String) as Map;
      expect(result['answer'], '5');
      expect(result['preloader'], false);
      expect(
        (result['css'] as List).every(
          (value) => !value.toString().startsWith('css/'),
        ),
        isTrue,
      );
      loaded = '';
      await web!.evaluateJavascript(
        source: "document.querySelector('.go-back-btn').click()",
      );
      await waitFor(() => loaded.endsWith('/toolbox.php'));
      loaded = '';
      await web!.evaluateJavascript(
        source: "document.querySelector('a.smart-toolbox-box[href\$=\"concretecalc.php\"]').click()",
      );
      await waitFor(() => loaded.contains('/calculators/concretecalc.php'));
      loaded = '';
      await web!.loadUrl(
        urlRequest: URLRequest(
          url: WebUri('https://www.progressivecommercial.com/'),
        ),
      );
      await waitFor(() => loaded.contains('progressivecommercial.com'));
      expect((await web!.getUrl())?.host, 'www.progressivecommercial.com');
      loaded = '';
      await web!.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(
            'https://justsmartchoice.com/subcontractor-agreement.php',
          ),
        ),
      );
      await waitFor(
        () => find
            .text('This resource is currently unavailable')
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.text('View Forms Library'));
      await tester.pump();
      await waitFor(() => loaded.endsWith('/forms.php'));
      await web!.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(
            'https://justsmartchoice.com/forms/change-order-form.pdf',
          ),
        ),
      );
      await waitFor(
        () => find
            .text('This resource is currently unavailable')
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.text('Back to Toolbox'));
      await tester.pump();
      await waitFor(() => loaded.endsWith('/toolbox.php'));
      expect(tester.takeException(), isNull);
    },
  );
}
