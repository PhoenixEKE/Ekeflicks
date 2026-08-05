// Central configuration for the EkeFlicks HTTP API.
//
// Override the origin at build time when the API is not served from the same
// origin as the web app, for example:
// `flutter run --dart-define=API_ORIGIN=https://api.ekeflicks.com`.

abstract final class ApiConfig {
  static const String configuredOrigin = String.fromEnvironment('API_ORIGIN');
  static const String productionOrigin = 'https://api.ekeflicks.com';
  static const String cdnOrigin = 'https://cdn.ekeflicks.com';
  static const String apiPrefix = '/api/v1';

  /// Retourne l'origine de l'API (production par défaut)
  static String get origin {
    if (configuredOrigin.trim().isNotEmpty) {
      return _withoutTrailingSlash(configuredOrigin.trim());
    }
    // Default to the production API instead of the web-dev origin
    // (for example http://192.162.68.247:3000).
    return productionOrigin;
  }

  /// URL de base de l'API
  static String get baseUrl => '${_withoutTrailingSlash(origin)}$apiPrefix';

  /// Génère une URL pour le CDN
  /// 
  /// Exemple:
  /// ```dart
  /// final url = ApiConfig.cdnEndpoint('avatars', 'user123.png');
  /// // Résultat: https://cdn.ekeflicks.com/avatars/user123.png
  /// ```
  static Uri cdnEndpoint(String bucket, String path) {
    final normalizedBucket = bucket.replaceAll(RegExp(r'^/+|/+$'), '');
    final normalizedPath = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .join('/');
    return Uri.parse('$cdnOrigin/$normalizedBucket/$normalizedPath');
  }

  /// Génère une URL pour l'API
  ///
  /// Exemple:
  /// ```dart
  /// final url = ApiConfig.endpoint('auth/register');
  /// // Résultat: https://api.ekeflicks.com/api/v1/auth/register/
  /// ```
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
