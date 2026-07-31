// lib/providers/avatar_provider.dart - Version la plus simple
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
      
      if (response.statusCode == 200) {
        // Approche simple avec cast direct
        final data = response.data as Map<String, dynamic>;
        final avatarsList = data['avatars'] as List;
        
        _avatars = avatarsList.cast<Map<String, dynamic>>().map((avatar) {
          return {
            'name': avatar['name']?.toString() ?? '',
            'url': avatar['url']?.toString() ?? '',
          };
        }).toList();
        
        print('✅ ${_avatars.length} avatars chargés');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur: $e');
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