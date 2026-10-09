import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_choice_mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Public footer, assistants and persistent platform cookie store',
    (tester) async {
      InAppWebViewController? publicPage;
      await tester.pumpWidget(
        SmartChoiceApp(
          onPageReady: (controller) async => publicPage = controller,
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (publicPage == null && DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
      }
      expect(publicPage, isNotNull);
      final result = await publicPage!.evaluateJavascript(
        source: '''JSON.stringify({
        host:location.hostname,
        legal:['/terms.php','/privacy.php','/cookie-policy.php','/accessibility.php',
          '/payment-refund-policy.php','/sms-communications-policy.php','/legal.php','/sitemap.php']
          .every(path=>Array.from(document.querySelectorAll('a[href]')).some(a=>new URL(a.href).pathname===path)),
        resources:['/partners.php','/investors.php'].every(path=>Array.from(document.querySelectorAll('a[href]')).some(a=>new URL(a.href).pathname===path)),
        assistant:!!document.querySelector('#smart-ai-open'),
        closeAssistant:!!document.querySelector('#smart-ai-close'),
        modes:Array.from(document.querySelectorAll('#smart-ai-mode button')).map(b=>b.textContent.trim()),
        input:!!document.querySelector('#smart-ai-input'),
        send:!!document.querySelector('#smart-ai-send')
      })''',
      );
      final public = Map<String, dynamic>.from(jsonDecode(result as String));
      expect(public['host'], 'justsmartchoice.com');
      expect(public['legal'], true);
      expect(public['resources'], true);
      expect(public['assistant'], true);
      expect(public['closeAssistant'], true);
      expect(public['modes'], ['Support', 'Estimate', 'Book Appointment']);
      expect(public['input'], true);
      expect(public['send'], true);

      // Dummy fixture on the distribution host; never touch CRM authentication cookies.
      final cookies = CookieManager.instance();
      final url = WebUri('https://mobile.justsmartchoice.com/');
      const name = 'sc_cookie_persistence_fixture';
      try {
        expect(
          await cookies.setCookie(
            url: url,
            name: name,
            value: 'disposable-fixture',
            expiresDate: DateTime.now()
                .add(const Duration(days: 7))
                .millisecondsSinceEpoch,
            isSecure: true,
            isHttpOnly: true,
            sameSite: HTTPCookieSameSitePolicy.LAX,
          ),
          true,
        );
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump();
        await tester.pumpWidget(const SmartChoiceApp());
        final remembered = await cookies.getCookie(url: url, name: name);
        expect(remembered?.value, 'disposable-fixture');
      } finally {
        await cookies.deleteCookie(url: url, name: name);
      }
    },
  );
}
