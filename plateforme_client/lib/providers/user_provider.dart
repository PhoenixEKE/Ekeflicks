import 'package:flutter/material.dart';
import 'package:app_ekeflicks/src/openapi.dart';
import 'package:app_ekeflicks/src/models/user.dart';
import 'package:app_ekeflicks/src/models/token_refresh.dart';
import 'package:dio/dio.dart';
import 'package:built_value/serializer.dart';

class UserProvider with ChangeNotifier {
  final Openapi apiClient;

  UserProvider(this.apiClient);

  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _hasActiveSubscription = false;

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshTokenValue => _refreshToken;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;
  bool get hasActiveSubscription => _hasActiveSubscription;

  /// Activates a zero-cost plan without creating a payment session.
  Future<void> activateFreeSubscription(String planSlug) async {
    final plansResponse = await apiClient.dio.get<Map<String, dynamic>>(
      '/subscription-plans/',
    );
    final payload = plansResponse.data;
    final rawPlans = payload?['results'] ?? payload;
    if (rawPlans is! List) {
      throw StateError('Liste des offres indisponible.');
    }

    final plan = rawPlans.cast<Map>().firstWhere(
      (item) => item['slug'] == planSlug,
      orElse: () => throw StateError('Offre gratuite indisponible.'),
    );
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      '/subscriptions/',
      data: {'plan_id': plan['id'], 'auto_renew': false},
    );
    if (response.data?['status'] != 'active') {
      throw StateError("L'offre gratuite n'a pas pu être activée.");
    }

    _hasActiveSubscription = true;
    notifyListeners();
  }

  void _setBearerToken(String token) {
    _accessToken = token;
    apiClient.dio.options.headers['Authorization'] = 'Bearer $token';
  }

  String _normalizeLoginIdentifier(String identifier) {
    final value = identifier.trim();
    if (value.contains('@')) return value.toLowerCase();
    final prefix = value.startsWith('+') ? '+' : '';
    return '$prefix${value.replaceAll(RegExp(r'\D'), '')}';
  }

  String? _apiErrorMessage(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        final message = _firstErrorValue(value);
        if (message != null) return message;
      }
    }

    final detail = data['detail'];
    return detail is String && detail.isNotEmpty ? detail : null;
  }

  String? _firstErrorValue(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is List) {
      for (final item in value) {
        final message = _firstErrorValue(item);
        if (message != null) return message;
      }
    }
    if (value is Map) {
      for (final item in value.values) {
        final message = _firstErrorValue(item);
        if (message != null) return message;
      }
    }
    return null;
  }

  /// Inscription d'un nouvel utilisateur + login automatique
  Future<bool> register({
    required String identifier,
    required String password,
    required String firstname,
    required String lastname,
  }) async {
    try {
      // Registration is an authentication endpoint in the v1 backend. The
      // generated legacy `/users/` operation no longer matches this API.
      final normalizedIdentifier = _normalizeLoginIdentifier(identifier);
      final isEmail = normalizedIdentifier.contains('@');
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/auth/register/',
        data: {
          if (isEmail) 'email': normalizedIdentifier,
          if (!isEmail) 'phone': normalizedIdentifier,
          'password': password,
          'firstname': firstname,
          'lastname': lastname,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data!;
        final access = data['access'] as String?;
        final refresh = data['refresh'] as String?;

        if (access != null) {
          _setBearerToken(access);
        }
        _refreshToken = refresh;
        _hasActiveSubscription = false;
        notifyListeners();

        if (access != null) {
          await _loadUserProfile();
        }
        return true;
      }

      return false;
    } on DioException catch (error) {
      // Never log request bodies here: they contain the user's password.
      if (error.response == null) {
        debugPrint('Registration network failure (${error.type.name})');
      }
      rethrow;
    }
  }

  /// Connexion utilisateur - Version modifiée pour retourner des informations détaillées
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final dio = Dio();
      dio.options.baseUrl = apiClient.dio.options.baseUrl;
      dio.interceptors.addAll(apiClient.dio.interceptors);

      final response = await dio.post(
        '/auth/login/',
        data: {
          // The API keeps the historical `email` key but accepts either an
          // email address or a telephone number as its value.
          'email': _normalizeLoginIdentifier(email),
          'password': password,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        _accessToken = data['access'] as String?;
        _refreshToken = data['refresh'] as String?;
        _hasActiveSubscription = data['has_active_subscription'] == true;

        if (_accessToken != null) {
          _setBearerToken(_accessToken!);
          final profileLoaded = await _loadUserProfile();

          return {
            'success': profileLoaded,
            'statusCode': 200,
            'message': profileLoaded ? 'Connexion réussie' : 'Erreur lors du chargement du profil'
          };
        }
      }

      return {
        'success': false,
        'statusCode': response.statusCode ?? 500,
        'message': _getErrorMessageFromStatusCode(response.statusCode)
      };
    } on DioException catch (e) {
      // Avoid printing Dio's verbose exception (and browser internals) for an
      // expected authentication failure. Keep only safe diagnostic metadata.
      if (e.response == null) {
        debugPrint('Login network failure (${e.type.name})');
      }

      // Gestion spécifique des erreurs Dio
      final statusCode = e.response?.statusCode;
      final errorMessage = _apiErrorMessage(e.response?.data) ??
          _getErrorMessageFromStatusCode(statusCode);

      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _hasActiveSubscription = false;
      notifyListeners();

      return {
        'success': false,
        'statusCode': statusCode ?? 500,
        'message': errorMessage,
        'dioError': e.message
      };
    } catch (e) {
      debugPrint('Unexpected login error: $e');

      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _hasActiveSubscription = false;
      notifyListeners();

      return {
        'success': false,
        'statusCode': 500,
        'message': 'Erreur inattendue lors de la connexion'
      };
    }
  }

  /// Méthode utilitaire pour obtenir le message d'erreur selon le code HTTP
  String _getErrorMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide';
      case 401:
        return 'Email ou mot de passe incorrect';
      case 403:
        return 'Nombre maximum de connexions simultanées atteint';
      case 404:
        return 'Utilisateur non trouvé';
      case 429:
        return 'Trop de tentatives de connexion. Veuillez réessayer plus tard';
      case 500:
        return 'Erreur interne du serveur';
      case 502:
        return 'Serveur temporairement indisponible';
      case 503:
        return 'Service temporairement indisponible';
      default:
        return 'Erreur de connexion';
    }
  }

  /// Charge le profil utilisateur connecté
  Future<bool> _loadUserProfile() async {
    if (_accessToken == null) return false;

    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>('/auth/me/');
      final data = response.data;

      if (data != null) {
        _currentUser = apiClient.serializers.deserialize(
          data,
          specifiedType: const FullType(User),
        ) as User;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  /// Rafraîchir le token
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final refreshRequest = TokenRefresh((b) => b..refresh = _refreshToken!);
      final tokenResponse = await apiClient.getAuthApi().authTokenRefreshCreate(
        data: refreshRequest,
      );

      if (tokenResponse.data?.access != null) {
        _accessToken = tokenResponse.data!.access;
        if (tokenResponse.data!.refresh != null) {
          _refreshToken = tokenResponse.data!.refresh;
        }

        _setBearerToken(_accessToken!);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  /// Déconnexion simple
  Future<void> logout() async {
    try {
      if (_accessToken != null && _refreshToken != null) {
        await apiClient.dio.post(
          '/auth/logout/',
          data: {'refresh': _refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      }
    } catch (e) {
      debugPrint('Logout API failed: $e');
      // On continue la déconnexion locale même si l'API échoue
    } finally {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _hasActiveSubscription = false;
      apiClient.dio.options.headers['Authorization'] = '';
      notifyListeners();
    }
  }

  Future<void> logoutAll({String? userId, bool confirmAll = false}) async {
    try {
      if (_accessToken != null) {
        final body = <String, dynamic>{};
        if (userId != null) body['user_id'] = userId;
        if (confirmAll) body['confirm_all'] = true;

        await apiClient.dio.post(
          '/auth/logout_all/',
          data: body,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      }
    } catch (e) {
      debugPrint('Logout all API failed: $e');
    } finally {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _hasActiveSubscription = false;
      apiClient.dio.options.headers['Authorization'] = '';
      notifyListeners();
    }
  }

  void reset() {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _hasActiveSubscription = false;
    apiClient.dio.options.headers['Authorization'] = '';
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    if (_accessToken == null) return false;

    try {
      return await _loadUserProfile();
    } catch (_) {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _hasActiveSubscription = false;
      notifyListeners();
      return false;
    }
  }
}
