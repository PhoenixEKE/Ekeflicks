/// Returns the application route targeted by a password or parental-PIN link.
///
/// Web onboarding links also use Flutter hash URLs such as #/signup.
String? deepLinkRoute(Uri uri) {
  final fragment = uri.fragment;
  final fragmentUri = fragment.startsWith('/') ? Uri.tryParse(fragment) : null;
  final target = fragmentUri ?? uri;
  final action = target.queryParameters['action'] ?? uri.queryParameters['action'];
  if (action == 'reset-password' || action == 'password-reset-confirm') return '/reset-password';
  if (action == 'reset-parental-pin') return '/reset-parental-pin';
  if (action == 'unsubscribe') return '/unsubscribe';

  if (target.pathSegments.isEmpty) return null;
  switch (target.pathSegments.first) {
    case 'reset-password':
    case 'password-reset-confirm':
      return '/reset-password';
    case 'reset-parental-pin':
      return '/reset-parental-pin';
    case 'unsubscribe':
      return '/unsubscribe';
    case 'signup':
      return '/signup';
    case 'login':
      return '/login';
    case 'subscription-step1':
      return '/subscription-step1';
    case 'payment':
      if (target.pathSegments.length > 1 && target.pathSegments[1] == 'return') return '/payment/return';
      break;
  }
  return null;
}
