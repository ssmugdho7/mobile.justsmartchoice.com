enum NavigationDecision { internal, external, blocked }

class NavigationPolicy {
  static final home = Uri.parse('https://mobile.justsmartchoice.com/admin');
  static const crmHost = 'mobile.justsmartchoice.com';
  static const meetingHost = 'meet.jit.si';
  static bool isHttps(Uri uri) =>
      uri.scheme == 'https' && uri.userInfo.isEmpty && uri.port == 443;
  static bool isCrm(Uri uri) => isHttps(uri) && uri.host == crmHost;
  static bool isOtherCrm(Uri uri) =>
      uri.host == 'crm.justsmartchoice.com' ||
      uri.host == 'dev.justsmartchoice.com';
  static bool canUseMedia(Uri uri) =>
      isHttps(uri) && (uri.host == crmHost || uri.host == meetingHost);

  static NavigationDecision decide(Uri uri) {
    if (isCrm(uri) || (isHttps(uri) && uri.host == meetingHost)) {
      return NavigationDecision.internal;
    }
    // Mobile testing must not silently open another CRM environment.
    if (isOtherCrm(uri)) {
      return NavigationDecision.blocked;
    }
    if (isHttps(uri) ||
        ((uri.scheme == 'mailto' || uri.scheme == 'tel') &&
            uri.path.isNotEmpty &&
            uri.userInfo.isEmpty)) {
      return NavigationDecision.external;
    }
    return NavigationDecision.blocked;
  }
}
