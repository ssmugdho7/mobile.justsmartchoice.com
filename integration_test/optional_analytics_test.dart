import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/crm_browser.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android intercepts optional analytics before a network response',
    (tester) async {
      InAppWebViewController? web;
      await tester.pumpWidget(
        MaterialApp(
          home: CrmBrowser(
            initialUri: Uri.parse('https://justsmartchoice.com/privacy.php'),
            onPageReady: (controller) async => web = controller,
          ),
        ),
      );
      Future<void> pause() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }

      final readyDeadline = DateTime.now().add(const Duration(seconds: 45));
      while (web == null && DateTime.now().isBefore(readyDeadline)) {
        await pause();
      }
      expect(web, isNotNull, reason: 'The real CrmBrowser must become ready');

      for (final host in [
        'www.googletagmanager.com',
        'www.google-analytics.com',
        'analytics.ahrefs.com',
      ]) {
        // A local inert document gets this HTTPS origin without requesting the
        // host's page. The one same-origin fixture GET omits credentials and
        // contains no account, client identifier or analytics event data. Its
        // expected 204 can only come from the app's local intercept response.
        await web!.loadData(
          baseUrl: WebUri('https://$host/'),
          data:
              '<!doctype html><html><head>'
              '<meta http-equiv="Content-Security-Policy" '
              'content="default-src \'none\'; connect-src https://$host">'
              '<title>Smart Choice blocker fixture: $host</title>'
              '</head><body>Local request-blocking fixture</body></html>',
        );
        final documentDeadline = DateTime.now().add(
          const Duration(seconds: 15),
        );
        var titleReady = false;
        while (!titleReady && DateTime.now().isBefore(documentDeadline)) {
          titleReady =
              await web!.evaluateJavascript(
                source:
                    'document.title === '
                    '"Smart Choice blocker fixture: $host"',
              ) ==
              true;
          if (!titleReady) await pause();
        }
        expect(titleReady, isTrue, reason: 'Fixture origin: $host');
        await web!.evaluateJavascript(
          source:
              "window.scBlockerStatus = null; "
              "fetch('/sc_blocker_fixture', "
              "{credentials:'omit', cache:'no-store'})"
              ".then(response => window.scBlockerStatus = response.status)"
              ".catch(() => window.scBlockerStatus = 'request-error'); null;",
        );
        dynamic status;
        final requestDeadline = DateTime.now().add(const Duration(seconds: 15));
        while (status == null && DateTime.now().isBefore(requestDeadline)) {
          status = await web!.evaluateJavascript(
            source: 'window.scBlockerStatus',
          );
          if (status == null) await pause();
        }
        expect(status, 204, reason: 'Analytics must be intercepted: $host');
        expect(tester.takeException(), isNull);
      }
    },
    // WebKit's native content rules deliberately surface a blocked request as
    // an error, not Android's empty local 204. It needs its own runtime check.
    skip: defaultTargetPlatform != TargetPlatform.android,
  );
}
