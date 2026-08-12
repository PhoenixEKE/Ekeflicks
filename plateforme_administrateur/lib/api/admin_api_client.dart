import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApiException implements Exception {
  final String message;
  final int? statusCode;
  const AdminApiException(this.message, [this.statusCode]);
  @override String toString() => message;
}

class AdminApiClient {
  AdminApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000/api/v1/admin'),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  final Map<String, String> _tokens = {};
  Future<void>? _renewal;

  Future<Map<String, dynamic>> login(String email, String password, String otp) async {
    final data = await _request('POST', '/auth/login/', authenticated: false, body: {
      'email': email, 'password': password, 'otp': otp,
      'device_id': 'ekeflicks-admin-web', 'device_type': 'admin-web',
    });
    await _saveTokens(data);
    return data;
  }

  Future<void> logout() async {
    final sessionId = _tokens['admin_session_id'];
    if (sessionId != null) {
      try { await _request('POST', '/sessions/$sessionId/revoke/'); } catch (_) {}
    }
    _tokens.clear();
  }

  Future<List<Map<String, dynamic>>> users({String? kind, String search = ''}) async {
    final query = Uri(queryParameters: {if (kind != null) 'kind': kind, if (search.isNotEmpty) 'search': search}).query;
    return _results(await _request('GET', '/users/?$query'));
  }
  Future<List<Map<String, dynamic>>> claims({String type = 'closure', String? status}) async {
    final query = Uri(queryParameters: {'type': type, if (status != null) 'status': status}).query;
    return _results(await _request('GET', '/claims/?$query'));
  }
  Future<List<Map<String, dynamic>>> roles() async => _results(await _request('GET', '/roles/'));
  Future<List<Map<String, dynamic>>> permissions() async => _results(await _request('GET', '/permissions/'));
  Future<Map<String, dynamic>> createRole(
    String name,
    List<int> permissionIds,
  ) async {
    final data = await _request(
      'POST',
      '/roles/',
      body: {'name': name, 'permissions': permissionIds},
    );
    return Map<String, dynamic>.from(data as Map);
  }
  Future<void> assignRoles(int userId, List<int> roleIds) async {
    await _request('PUT', '/users/$userId/roles/', body: {'role_ids': roleIds});
  }

  List<Map<String, dynamic>> _results(dynamic data) =>
      List<Map<String, dynamic>>.from(data is Map && data['results'] is List ? data['results'] : data as List);

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body, bool authenticated = true, bool retry = true}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (authenticated) {
      final token = _tokens['admin_access'];
      if (token == null) throw const AdminApiException('Session administrateur absente.', 401);
      headers['Authorization'] = 'Bearer $token';
    }
    final request = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await _http.send(request).timeout(const Duration(seconds: 15)));
    if (response.statusCode == 401 && authenticated && retry) {
      await _renew();
      return _request(method, path, body: body, retry: false);
    }
    final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(data is Map ? (data['detail']?.toString() ?? 'Erreur API') : 'Erreur API', response.statusCode);
    }
    return data;
  }

  Future<void> _renew() async {
    if (_renewal != null) return _renewal;
    final completer = Completer<void>(); _renewal = completer.future;
    try {
      final refresh = _tokens['admin_refresh'];
      if (refresh == null) throw const AdminApiException('Session expirée.', 401);
      final data = await _request('POST', '/auth/refresh/', authenticated: false,
          body: {'refresh': refresh, 'device_id': 'ekeflicks-admin-web', 'device_type': 'admin-web'});
      await _saveTokens(data); completer.complete();
    } catch (error, stack) { _tokens.clear(); completer.completeError(error, stack); rethrow; }
    finally { _renewal = null; }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    _tokens['admin_access'] = data['access'] as String;
    _tokens['admin_refresh'] = data['refresh'] as String;
    _tokens['admin_session_id'] = data['session_id'].toString();
  }
}
