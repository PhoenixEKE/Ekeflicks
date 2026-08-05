// Central configuration for the EkeFlicks HTTP API.
//
// Override the origin at build time when the API is not served from the same
// origin as the web app, for example:
// `flutter run --dart-define=API_ORIGIN=https://api.ekeflicks.com`.
import 'platform_origin_stub.dart'
    if (dart.library.html) 'platform_origin_web.dart';

abstract final class ApiConfig {
  static const String configuredOrigin = String.fromEnvironment('API_ORIGIN');
  static const String localOrigin = 'http://localhost:8000';
  static const String apiPrefix = '/api/v1';

  static String get origin {
    if (configuredOrigin.trim().isNotEmpty) {
      return _withoutTrailingSlash(configuredOrigin.trim());
    }
    return _withoutTrailingSlash(currentBrowserOrigin() ?? localOrigin);
  }

  static String get baseUrl => '${_withoutTrailingSlash(origin)}$apiPrefix';

  static Uri endpoint(String path) {
    final normalizedPath = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .join('/');
    return Uri.parse('$baseUrl/$normalizedPath/');
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
