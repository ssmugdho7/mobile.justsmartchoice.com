@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/embedded_page_web.dart';
import 'package:web/web.dart' as web;

void main() {
  test('CRM frame delegates media only to exact CRM and Jitsi origins', () {
    final frame = web.HTMLIFrameElement();
    applyEmbeddedMediaPermissions(
      frame,
      Uri.parse('https://crm.justsmartchoice.com/admin'),
    );
    expect(
      frame.getAttribute('allow'),
      'camera https://crm.justsmartchoice.com https://meet.jit.si; '
      'microphone https://crm.justsmartchoice.com https://meet.jit.si; '
      'fullscreen https://crm.justsmartchoice.com https://meet.jit.si',
    );
    expect(frame.getAttribute('allow'), isNot(contains('*')));
  });

  test(
    'public, provider and impersonated destinations lose media delegation',
    () {
      final frame = web.HTMLIFrameElement();
      for (final destination in [
        'public-pages/about.html',
        'https://justsmartchoice.com/',
        'https://www.progressivecommercial.com/',
        'https://meet.jit.si.evil.example/',
        'https://user@crm.justsmartchoice.com/admin',
        'https://crm.justsmartchoice.com:8443/admin',
      ]) {
        applyEmbeddedMediaPermissions(
          frame,
          Uri.parse('https://meet.jit.si/room'),
        );
        expect(frame.hasAttribute('allow'), isTrue);
        applyEmbeddedMediaPermissions(frame, Uri.parse(destination));
        expect(frame.hasAttribute('allow'), isFalse, reason: destination);
      }
    },
  );
}
