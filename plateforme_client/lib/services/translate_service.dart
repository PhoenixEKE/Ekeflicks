import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_ekeflicks/core/api_config.dart';

class TranslateService {
  static Uri _endpoint(String key, {String? lang}) =>
      ApiConfig.endpoint('translations/translate').replace(queryParameters: {
        'key': key,
        if (lang != null) 'lang': lang,
      });

  /// Récupère le texte traduit selon la clé et la langue (optionnelle)
  static Future<String?> fetchTranslatedText(String key, {String? lang}) async {
    try {
      final uri = _endpoint(key, lang: lang);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["text"];
      } else {
        debugPrint("Erreur traduction: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Erreur réseau traduction: $e");
      return null;
    }
  }
}
