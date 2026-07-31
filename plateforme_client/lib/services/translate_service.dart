import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslateService {
  static const String baseUrl = "http://180.149.198.245:80/api/v1/translations/translate/";

  /// Récupère le texte traduit selon la clé et la langue (optionnelle)
  static Future<String?> fetchTranslatedText(String key, {String? lang}) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        "key": key,
        if (lang != null) "lang": lang,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["text"];
      } else {
        print("Erreur traduction: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erreur réseau traduction: $e");
      return null;
    }
  }
}
