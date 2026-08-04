/// Central configuration for the EkeFlicks HTTP API.
///
/// The origin can be overridden at build time, for example:
/// `flutter run --dart-define=API_ORIGIN=https://api.ekeflicks.com`.
abstract final class ApiConfig {
  static const String origin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: 'http://180.149.198.245',
  );

  static const String apiPrefix = '/api/v1';

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
