import 'package:flutter/foundation.dart';
import '../api/admin_api_client.dart';

class AdminAuthProvider extends ChangeNotifier {
  AdminAuthProvider(this.api);
  final AdminApiClient api;
  bool busy = false;
  String? error;

  Future<bool> login(String email, String password, String otp) async {
    busy = true; error = null; notifyListeners();
    try { await api.login(email, password, otp); return true; }
    on AdminApiException catch (e) { error = e.message; return false; }
    catch (_) { error = 'Le service administrateur est indisponible.'; return false; }
    finally { busy = false; notifyListeners(); }
  }

  Future<void> logout() async { await api.logout(); notifyListeners(); }
}
