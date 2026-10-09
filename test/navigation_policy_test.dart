import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/navigation_policy.dart';
import 'package:smart_choice_mobile/document_download.dart';

void main() {
  test('Existing CRM routes and Jitsi rooms stay in the app', () {
    expect(
      NavigationPolicy.decide(NavigationPolicy.websiteHome),
      NavigationDecision.internal,
    );
    expect(
      NavigationPolicy.decide(NavigationPolicy.websiteAbout),
      NavigationDecision.internal,
    );
    expect(NavigationPolicy.canUseMedia(NavigationPolicy.websiteHome), isFalse);
    expect(NavigationPolicy.isCrm(NavigationPolicy.websiteHome), isFalse);
    expect(
      NavigationPolicy.decide(NavigationPolicy.home),
      NavigationDecision.internal,
    );
    expect(
      NavigationPolicy.decide(
        Uri.parse('https://crm.justsmartchoice.com/proposal/1/key'),
      ),
      NavigationDecision.internal,
    );
    expect(
      NavigationPolicy.decide(Uri.parse('https://meet.jit.si/room')),
      NavigationDecision.internal,
    );
  });
  test('Development, insecure and unsafe URLs cannot navigate', () {
    for (final value in [
      'https://dev.justsmartchoice.com/admin',
      'http://crm.justsmartchoice.com/admin',
      'https://crm.justsmartchoice.com:8443/admin',
      'https://user@crm.justsmartchoice.com/admin',
      'file:///etc/passwd',
      'javascript:alert(1)',
      'intent://scan/',
      'data:text/html,hello',
      'about:blank',
    ]) {
      expect(
        NavigationPolicy.decide(Uri.parse(value)),
        NavigationDecision.blocked,
        reason: value,
      );
    }
    expect(
      NavigationPolicy.isOtherCrm(
        Uri.parse('https://dev.justsmartchoice.com/api/upload'),
      ),
      isTrue,
    );
    expect(NavigationPolicy.isOtherCrm(NavigationPolicy.home), isFalse);
  });
  test('External links do not inherit CRM cookies or media permissions', () {
    for (final value in [
      'https://example.com',
      'https://mobile.justsmartchoice.com/',
      'https://mobile.justsmartchoice.com.evil.test',
      'https://meet.jit.si.evil.test',
      'mailto:support@example.com',
      'tel:+18135550100',
    ]) {
      final uri = Uri.parse(value);
      expect(NavigationPolicy.decide(uri), NavigationDecision.external);
      expect(NavigationPolicy.canUseMedia(uri), isFalse);
      expect(NavigationPolicy.isCrm(uri), isFalse);
    }
    expect(
      NavigationPolicy.canUseMedia(Uri.parse('https://meet.jit.si/room')),
      isTrue,
    );
    expect(
      NavigationPolicy.isCrm(Uri.parse('https://meet.jit.si/room')),
      isFalse,
    );
  });
  test(
    'Download names cannot contain path traversal or control characters',
    () {
      expect(
        DocumentDownload.safeName('../../estimate.pdf', 'application/pdf'),
        'estimate.pdf',
      );
      expect(
        DocumentDownload.safeName('..\\contract.pdf', 'application/pdf'),
        'contract.pdf',
      );
      expect(
        DocumentDownload.safeName('', 'application/pdf'),
        'CRM-document.pdf',
      );
      expect(
        DocumentDownload.safeName('..', 'application/pdf'),
        'CRM-document.pdf',
      );
      expect(
        DocumentDownload.safeName('invo\u0000ice.pdf', 'application/pdf'),
        'invo_ice.pdf',
      );
    },
  );
}
