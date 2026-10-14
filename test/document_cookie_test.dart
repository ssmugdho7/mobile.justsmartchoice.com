import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/document_cookie.dart';

void main() {
  final uri = Uri.parse('https://crm.justsmartchoice.com/download/proposal');
  final now = DateTime.utc(2026, 10, 15);
  Cookie fixture(
    String name, {
    String? domain = 'crm.justsmartchoice.com',
    String? path = '/',
    int? expiry,
    bool? secure,
    String value = 'fixture-value',
  }) => Cookie(
    name: name,
    value: value,
    domain: domain,
    path: path,
    expiresDate: expiry,
    isSecure: secure,
  );

  test(
    'CRM download excludes unrelated suffix domains from iOS cookie results',
    () {
      final header = DocumentCookies.header(uri, [
        fixture('crm'),
        fixture('parent', domain: '.justsmartchoice.com'),
        fixture('parentHost', domain: 'justsmartchoice.com'),
        fixture('suffix', domain: 'choice.com'),
        fixture('subdomain', domain: 'downloads.crm.justsmartchoice.com'),
        fixture('external', domain: 'example.com'),
      ], now: now);
      expect(header, 'crm=fixture-value; parent=fixture-value');
    },
  );

  test('Paths match directory boundaries, not coincidental prefixes', () {
    final header = DocumentCookies.header(uri, [
      fixture('root'),
      fixture('directory', path: '/download'),
      fixture('directorySlash', path: '/download/'),
      fixture('exact', path: '/download/proposal'),
      fixture('prefix', path: '/down'),
      fixture('admin', path: '/admin'),
      fixture('child', path: '/download/proposal/edit'),
    ], now: now);
    expect(
      header,
      'root=fixture-value; directory=fixture-value; directorySlash=fixture-value; exact=fixture-value',
    );
  });

  test('Expired cookies are excluded while valid persistent and session cookies remain', () {
    final header = DocumentCookies.header(uri, [
      fixture('session'),
      fixture(
        'persistent',
        expiry: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
      ),
      fixture(
        'expired',
        expiry: now
            .subtract(const Duration(milliseconds: 1))
            .millisecondsSinceEpoch,
      ),
      fixture('expiresNow', expiry: now.millisecondsSinceEpoch),
    ], now: now);
    expect(header, 'session=fixture-value; persistent=fixture-value');
  });

  test(
    'Secure cookies are retained for HTTPS CRM and never exported outside it',
    () {
      final cookies = [
        fixture('secure', secure: true),
        fixture('legacy', secure: false),
      ];
      expect(
        DocumentCookies.header(uri, cookies, now: now),
        'secure=fixture-value; legacy=fixture-value',
      );
      for (final outside in [
        uri.replace(scheme: 'http'),
        uri.replace(host: 'example.com'),
        uri.replace(host: 'dev.justsmartchoice.com'),
        uri.replace(userInfo: 'user'),
      ]) {
        expect(DocumentCookies.header(outside, cookies, now: now), isEmpty);
      }
    },
  );

  test('Missing cookie domains fail closed except for explicitly scoped older Android results', () {
    final cookies = [fixture('androidSession', domain: null, path: null)];
    expect(DocumentCookies.header(uri, cookies, now: now), isEmpty);
    expect(
      DocumentCookies.header(uri, cookies, now: now, allowMissingDomain: true),
      'androidSession=fixture-value',
    );
    expect(
      DocumentCookies.header(
        uri,
        [fixture('suffix', domain: 'choice.com')],
        now: now,
        allowMissingDomain: true,
      ),
      isEmpty,
    );
  });

  test('Malformed cookies cannot add header fields or extra cookie pairs', () {
    expect(
      DocumentCookies.header(uri, [
        fixture('valid', value: 'encoded%2Fvalue='),
        fixture('bad;name'),
        fixture('badValue', value: 'value; other=injected'),
        fixture('newLine', value: 'value\r\nInjected: header'),
        Cookie(
          name: 'nonString',
          value: 123,
          domain: 'crm.justsmartchoice.com',
        ),
      ], now: now),
      'valid=encoded%2Fvalue=',
    );
  });
}
