import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/optional_analytics.dart';

void main() {
  final rules = optionalAnalyticsContentBlockers(usesWebKit: true);
  test('Android uses the request interceptor instead of native rules', () {
    expect(optionalAnalyticsContentBlockers(usesWebKit: false), isEmpty);
  });
  test('optional analytics scripts and collection URLs are blocked', () {
    for (final url in [
      'https://www.googletagmanager.com/gtag/js?id=fixture',
      'https://www.google-analytics.com/g/collect',
      'https://region1.google-analytics.com:443/g/collect',
      'https://analytics.ahrefs.com/analytics.js',
      'https://ANALYTICS.AHREFS.COM/api/event',
      'http://google-analytics.com',
    ]) {
      expect(isOptionalAnalyticsRequest(Uri.parse(url)), isTrue, reason: url);
    }
    expect(rules, hasLength(3));
    for (final rule in rules) {
      expect(rule.toMap()['action'], {'type': 'block'});
      expect(rule.trigger.urlFilterIsCaseSensitive, isFalse);
    }
  });
  test(
    'CRM, CAPTCHA, login, meetings and unrelated sites remain available',
    () {
      for (final url in [
        'https://crm.justsmartchoice.com/products/client',
        'https://crm.justsmartchoice.com/admin/authentication',
        'https://justsmartchoice.com/privacy.php',
        'https://accounts.google.com/o/oauth2/auth',
        'https://www.google.com/recaptcha/api.js',
        'https://www.gstatic.com/recaptcha/releases/fixture.js',
        'https://meet.jit.si/external_api.js',
        'https://checkout.stripe.com/pay/fixture',
        'https://google-analytics.com.example.org/',
        'https://example.org/google-analytics.com/',
        'https://google-analytics.com@example.org/',
        'https://notgoogle-analytics.com/',
        'https://ahrefs.com/',
      ]) {
        expect(
          isOptionalAnalyticsRequest(Uri.parse(url)),
          isFalse,
          reason: url,
        );
      }
    },
  );
}
