import 'navigation_policy.dart';

class PreviewDestination {
  static const pages = {
    '/': 'home',
    '/index.php': 'home',
    '/about.php': 'about',
    '/contacts.php': 'contact',
    '/toolbox.php': 'toolbox',
    '/fractionscalc.php': 'fractions',
    '/pricing.php': 'pricing',
  };
  // Confirmed missing on the public website; never send users to a broken tab.
  static const missingTools = {
    '/calculator.php',
    '/concretecalc.php',
    '/feet-inches-calculator.php',
    '/flooring-calculator.php',
    '/paint-calculator.php',
    '/vinyl-fence-calculator.php',
  };
  static Uri source(Uri uri) {
    if (NavigationPolicy.isWebsite(uri) && pages.containsKey(uri.path)) {
      return Uri.parse(
        'public-pages/${pages[uri.path]}.html?v=${const String.fromEnvironment('PREVIEW_COMMIT', defaultValue: 'local')}',
      );
    }
    return uri;
  }
}
