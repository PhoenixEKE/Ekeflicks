// services/avatar_service.dart
import 'package:app_ekeflicks/src/openapi.dart';

class AvatarService {
  final Openapi openapi;

  AvatarService(this.openapi);

  Future<List<Map<String, String>>> getAvatars() async {
    try {
      final response = await openapi.getAvatarsApi().avatarsList();
      
      // La réponse devrait être déjà parsée grâce aux intercepteurs
      if (response.statusCode == 200) {
        // Adaptez cette partie selon la structure réelle de la réponse
        // Basé sur votre JSON, ça semble être une liste d'objets avec name et url
        final data = response.data;
        
        if (data is Map && data.containsKey('avatars')) {
          final List<dynamic> avatarsList = data['avatars'];
          
          return avatarsList.map<Map<String, String>>((avatar) {
            return {
              'name': avatar['name'] ?? '',
              'url': avatar['url'] ?? '',
            };
          }).toList();
        } else {
          throw Exception('Format de réponse inattendu');
        }
      } else {
        throw Exception('Échec du chargement des avatars: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Échec du chargement des avatars: $e');
    }
  }
}