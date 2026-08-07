// lib/providers/avatar_provider.dart
import 'package:flutter/foundation.dart';
import 'package:app_ekeflicks/src/openapi.dart';

class AvatarProvider with ChangeNotifier {
  List<Map<String, String>> _avatars = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, String>> get avatars => _avatars;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAvatars(Openapi openapi) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await openapi.getAvatarsApi().avatarsList();
      final data = response.data;
      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw Exception('Réponse invalide (${response.statusCode})');
      }

      final avatarData = data['avatars'];
      if (avatarData is! List) {
        throw Exception('Liste des avatars absente de la réponse');
      }

      _avatars = avatarData
          .whereType<Map<String, dynamic>>()
          .map((avatar) => {
                'name': avatar['name']?.toString() ?? '',
                'url': avatar['url']?.toString() ?? '',
              })
          .where((avatar) => avatar['url']!.isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      _error = error.toString();
      debugPrint('Erreur de chargement des avatars: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
