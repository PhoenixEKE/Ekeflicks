import 'dart:convert';

import 'package:plateforme_producteurs/models/producer_session.dart';
import 'package:plateforme_producteurs/services/api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ApiClient _api = ApiClient.instance;

  ProducerUser? _currentUser;

  ProducerUser? get currentUser => _currentUser;

  bool get isAuthenticated => _api.hasAccessToken && _currentUser != null;

  Future<ProducerSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/api/v1/auth/web/login/',
      body: {'email': email.trim(), 'password': password},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Identifiant ou mot de passe incorrect.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final access = data['access']?.toString();

    if (access == null || access.isEmpty) {
      throw const ApiException(
        'Le serveur n’a pas retourné de session valide.',
      );
    }

    _api.setAccessToken(access);

    try {
      final user = await me();

      if (!user.isProducer) {
        await logout();

        throw const ApiException(
          'Ce compte n’est pas autorisé sur l’espace Producteurs EKEFLICKS.',
          statusCode: 403,
        );
      }

      if (!user.isActive) {
        await logout();

        throw const ApiException(
          'Ce compte Producteur est désactivé.',
          statusCode: 403,
        );
      }

      _currentUser = user;

      return ProducerSession(accessToken: access, user: user);
    } catch (_) {
      if (_currentUser == null) {
        _api.setAccessToken(null);
      }
      rethrow;
    }
  }

  Future<ProducerUser> me() async {
    final response = await _api.get('/api/v1/auth/me/', authenticated: true);

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de récupérer le compte Producteur.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body);

    final Map<String, dynamic> userData;

    if (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>) {
      userData = Map<String, dynamic>.from(data['user']);
    } else if (data is Map<String, dynamic>) {
      userData = data;
    } else {
      throw const ApiException('Réponse utilisateur invalide.');
    }

    final user = ProducerUser.fromJson(userData);
    _currentUser = user;

    return user;
  }

  Future<bool> restoreSession() async {
    final response = await _api.post('/api/v1/auth/web/refresh/');

    if (response.statusCode != 200) {
      _api.setAccessToken(null);
      _currentUser = null;
      return false;
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      return false;
    }

    final access = data['access']?.toString();

    if (access == null || access.isEmpty) {
      return false;
    }

    _api.setAccessToken(access);

    try {
      final user = await me();

      if (!user.isProducer || !user.isActive) {
        await logout();
        return false;
      }

      return true;
    } catch (_) {
      _api.setAccessToken(null);
      _currentUser = null;
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/v1/auth/web/logout/');
    } finally {
      _api.setAccessToken(null);
      _currentUser = null;
    }
  }
}
