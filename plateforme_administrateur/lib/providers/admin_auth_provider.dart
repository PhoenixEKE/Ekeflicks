import 'package:flutter/foundation.dart';
import '../api/admin_api_client.dart';

class AdminAuthProvider extends ChangeNotifier {
  AdminAuthProvider(this.api);
  final AdminApiClient api;
  bool busy = false;
  String? error;
  Map<String, dynamic>? user;

  bool can(String permission) {
    final permissions = List<String>.from(user?['permissions'] ?? const []);
    return permissions.contains('*') || permissions.contains(permission);
  }

  bool get isSuperuser => user?['is_superuser'] == true;

  Future<bool> login(String email, String password, String otp) async {
    busy = true; error = null; notifyListeners();
    try {
      final response = await api.login(email, password, otp);
      user = Map<String, dynamic>.from(response['user'] as Map);
      return true;
    }
    on AdminApiException catch (e) { error = e.message; return false; }
    catch (_) { error = 'Le service administrateur est indisponible.'; return false; }
    finally { busy = false; notifyListeners(); }
  }

  Future<void> logout() async {
    await api.logout();
    user = null;
    notifyListeners();
  }
}
