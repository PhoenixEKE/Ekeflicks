// lib/services/geolocation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeolocationService {
  static const String _ipApiUrl = 'http://ip-api.com/json/';
  static const String _ipApiUrlBackup = 'https://ipapi.co/json/';

  /// Détecte le pays basé sur l'adresse IP
  static Future<Map<String, dynamic>?> detectCountryByIP() async {
    try {
      final response = await http.get(Uri.parse(_ipApiUrl)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'country': data['country'],
          'countryCode': data['countryCode'],
          'city': data['city'],
          'region': data['region'],
          'timezone': data['timezone'],
          'query': data['query'], // IP address
        };
      }
    } catch (e) {
      print('Erreur détection IP principale: $e');
      // Essayer le service de backup
      return await _tryBackupService();
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _tryBackupService() async {
    try {
      final response = await http.get(Uri.parse(_ipApiUrlBackup)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'country': data['country_name'],
          'countryCode': data['country_code'],
          'city': data['city'],
          'region': data['region'],
          'timezone': data['timezone'],
          'query': data['ip'],
        };
      }
    } catch (e) {
      print('Erreur détection IP backup: $e');
    }
    return null;
  }

  /// Liste réduite des pays les plus courants
  static final List<Map<String, String>> popularCountries = [
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
    {'code': 'US', 'name': 'États-Unis', 'flag': '🇺🇸'},
    {'code': 'GB', 'name': 'Royaume-Uni', 'flag': '🇬🇧'},
    {'code': 'DE', 'name': 'Allemagne', 'flag': '🇩🇪'},
    {'code': 'IT', 'name': 'Italie', 'flag': '🇮🇹'},
    {'code': 'ES', 'name': 'Espagne', 'flag': '🇪🇸'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'BE', 'name': 'Belgique','flag':'🇧🇪'},
    {'code': 'CH', 'name': 'Suisse', 'flag': '🇨🇭'},
    {'code': 'CI', 'name': 'Côte d\'Ivoire', 'flag': '🇨🇮'},
    {'code': 'SN', 'name': 'Sénégal', 'flag': '🇸🇳'},
    {'code': 'CM', 'name': 'Cameroun', 'flag': '🇨🇲'},
    {'code': 'MG', 'name': 'Madagascar', 'flag': '🇲🇬'},
    {'code': 'MA', 'name': 'Maroc', 'flag': '🇲🇦'},
    {'code': 'TN', 'name': 'Tunisie', 'flag': '🇹🇳'},
    {'code': 'DZ', 'name': 'Algérie', 'flag': '🇩🇿'},
    {'code': 'JP', 'name': 'Japon', 'flag': '🇯🇵'},
    {'code': 'KR', 'name': 'Corée du Sud', 'flag': '🇰🇷'},
    {'code': 'CN', 'name': 'Chine', 'flag': '🇨🇳'},
    {'code': 'BR', 'name': 'Brésil', 'flag': '🇧🇷'},
    {'code': 'AU', 'name': 'Australie', 'flag': '🇦🇺'},
  ];
}