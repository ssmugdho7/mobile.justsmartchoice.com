import 'navigation_policy.dart';
import 'toolbox_navigation.dart';

class PreviewDestination {
  static const pages = {
    '/': 'home',
    '/index.php': 'home',
    '/about.php': 'about',
    '/contacts.php': 'contact',
    '/toolbox.php': 'toolbox',
    '/fractionscalc.php': 'fractions',
    '/pricing.php': 'pricing',
    '/forms.php': 'forms',
    '/contracts.php': 'contracts',
    '/calculator.php': 'calculator',
    '/concretecalc.php': 'concretecalc',
    '/concrete-calculator.php': 'concretecalc',
    '/feet-inches-calculator.php': 'feet-inches-calculator',
    '/flooring-calculator.php': 'flooring-calculator',
    '/paint-calculator.php': 'paint-calculator',
    '/vinyl-fence-calculator.php': 'vinyl-fence-calculator',
    '/calculators/calculator.php': 'calculator',
    '/calculators/concretecalc.php': 'concretecalc',
    '/calculators/feet-inches-calculator.php': 'feet-inches-calculator',
    '/calculators/flooring-calculator.php': 'flooring-calculator',
    '/calculators/paint-calculator.php': 'paint-calculator',
    '/calculators/vinyl-fence-calculator.php': 'vinyl-fence-calculator',
  };
  static const missingTools = ToolboxNavigation.missingResources;
  static Uri source(Uri uri) {
    uri = ToolboxNavigation.resolve(uri);
    if (NavigationPolicy.isWebsite(uri) && pages.containsKey(uri.path)) {
      return Uri.parse(
        'public-pages/${pages[uri.path]}.html?v=${const String.fromEnvironment('PREVIEW_COMMIT', defaultValue: 'local')}',
      ).replace(fragment: uri.hasFragment ? uri.fragment : null);
    }
    return uri;
  }
}
