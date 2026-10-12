import 'navigation_policy.dart';

class ToolboxNavigation {
  static const calculatorNames = {
    'calculator.php',
    'concretecalc.php',
    'feet-inches-calculator.php',
    'flooring-calculator.php',
    'paint-calculator.php',
    'vinyl-fence-calculator.php',
  };
  static const missingResources = {
    '/subcontractor-agreement.php',
    '/renovation-agreement.php',
    '/forms/credit-card-authorization.pdf',
    '/forms/change-order-form.pdf',
    '/forms/lien-release-form.pdf',
    '/forms/final-payment-affidavit.pdf',
    '/forms/bid-proposal-form.pdf',
  };
  static Uri resolve(Uri uri) {
    if (NavigationPolicy.isWebsite(uri) &&
        uri.path == '/notice-of-commencement.php') {
      return uri.replace(
        path: '/forms.php',
        fragment: 'notice-of-commencement',
      );
    }
    if (NavigationPolicy.isWebsite(uri) &&
        uri.path == '/concrete-calculator.php') {
      return uri.replace(path: '/calculators/concretecalc.php');
    }
    if (NavigationPolicy.isWebsite(uri) &&
        uri.path.startsWith('/') &&
        calculatorNames.contains(uri.path.substring(1))) {
      return uri.replace(path: '/calculators${uri.path}');
    }
    return uri;
  }

  static bool isMissingResource(Uri uri) =>
      NavigationPolicy.isWebsite(uri) && missingResources.contains(uri.path);
}
