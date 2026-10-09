enum NavigationDecision { internal, external, blocked }

class NavigationPolicy {
  static final home = Uri.parse('https://crm.justsmartchoice.com/admin');
  static final websiteHome = Uri.parse('https://justsmartchoice.com/');
  static final websiteAbout = websiteHome.resolve('/about.php');
  static const crmHost = 'crm.justsmartchoice.com';
  static const appSiteHost = 'mobile.justsmartchoice.com';
  static const meetingHost = 'meet.jit.si';
  static bool isHttps(Uri uri) =>
      uri.scheme == 'https' && uri.userInfo.isEmpty && uri.port == 443;
  static bool isCrm(Uri uri) => isHttps(uri) && uri.host == crmHost;
  static bool isWebsite(Uri uri) =>
      isHttps(uri) &&
      (uri.host == 'justsmartchoice.com' ||
          uri.host == 'www.justsmartchoice.com');
  static bool isAppPage(Uri uri) => isCrm(uri) || isWebsite(uri);
  static bool isOtherCrm(Uri uri) => uri.host == 'dev.justsmartchoice.com';
  static bool canUseMedia(Uri uri) =>
      isHttps(uri) && (uri.host == crmHost || uri.host == meetingHost);

  static NavigationDecision decide(Uri uri) {
    if (isAppPage(uri) || (isHttps(uri) && uri.host == meetingHost)) {
      return NavigationDecision.internal;
    }
    // Never switch the live-account app to a different CRM environment.
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
