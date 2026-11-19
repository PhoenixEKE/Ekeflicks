import 'package:flutter/foundation.dart';
import 'package:app_ekeflicks/src/openapi.dart';
import 'package:app_ekeflicks/src/models/user.dart';
import 'package:app_ekeflicks/src/models/token_refresh.dart';
import 'package:dio/dio.dart';
import 'package:built_value/serializer.dart';
import 'package:app_ekeflicks/services/geolocation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_ekeflicks/core/dio_credentials.dart';

class UserProvider with ChangeNotifier {
  final Openapi apiClient;

  UserProvider(this.apiClient) {
    configureDioCredentials(apiClient.dio);
  }

  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _hasActiveSubscription = false;
  String? _accountPhone;

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshTokenValue => _refreshToken;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;
  bool get hasActiveSubscription => _hasActiveSubscription;
  String? get accountPhone => _accountPhone;

  /// Activates a zero-cost plan without creating a payment session.
  Future<void> activateFreeSubscription(String planSlug) async {
    // 1. Récupérer la liste des plans
    final plansResponse = await apiClient.dio.get<Map<String, dynamic>>(
      '/subscription-plans/',
    );
    final payload = plansResponse.data;
    final rawPlans = payload?['results'] ?? payload;
    if (rawPlans is! List) {
      throw StateError('Liste des offres indisponible.');
    }

    // 2. Trouver le plan par son slug
    final plan = rawPlans.cast<Map>().firstWhere(
      (item) => item['slug'] == planSlug,
      orElse: () => throw StateError('Offre gratuite indisponible.'),
    );

    // 3. Créer l'abonnement avec auto_renew = false
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      '/subscriptions/',
      data: {'plan_id': plan['id'], 'auto_renew': false},
    );

    // 4. Vérifier que l'abonnement est actif
    if (response.data?['status'] != 'active') {
      throw StateError("L'offre gratuite n'a pas pu être activée.");
    }

    // 5. Mettre à jour le statut
    _hasActiveSubscription = true;
    notifyListeners();
  }

  /// Creates a paid subscription and initializes a Stripe Checkout session.
  ///
  /// The backend remains the source of truth for the plan price/currency.
  Future<String> startStripeCheckout(String planSlug) async {
    // 1. Load the active plans from the backend.
    final plansResponse = await apiClient.dio.get<Map<String, dynamic>>(
      '/subscription-plans/',
    );

    final payload = plansResponse.data;
    final rawPlans = payload?['results'] ?? payload;

    if (rawPlans is! List) {
      throw StateError('Liste des offres indisponible.');
    }

    final plan = rawPlans.cast<Map>().firstWhere(
      (item) => item['slug'] == planSlug && item['is_active'] == true,
      orElse: () => throw StateError('Offre indisponible.'),
    );

    final planId = plan['id'];

    if (planId == null) {
      throw StateError('Identifiant de l\'offre indisponible.');
    }

    // 2. Create the pending paid subscription.
    final subscriptionResponse = await apiClient.dio.post<Map<String, dynamic>>(
      '/subscriptions/',
      data: {'plan_id': planId, 'auto_renew': true},
    );

    final subscriptionId = subscriptionResponse.data?['id'];

    if (subscriptionId == null) {
      throw StateError('Impossible de créer l\'abonnement.');
    }

    // 3. Ask the backend to create the Stripe Checkout session.
    final paymentResponse = await apiClient.dio.post<Map<String, dynamic>>(
      '/payments/',
      data: {'subscription_id': subscriptionId, 'provider': 'stripe'},
    );

    final checkoutUrl = paymentResponse.data?['checkout_url'];

    if (checkoutUrl is! String || checkoutUrl.isEmpty) {
      throw StateError('Stripe Checkout indisponible.');
    }

    // Stripe ouvre une page externe et Flutter Web sera rechargé
    // lors du retour. On persiste donc explicitement le refresh token
    // juste avant de quitter EKEFLICKS.
    await _persistRefreshToken();

    return checkoutUrl;
  }

  static const String _refreshTokenStorageKey = 'ekeflicks_auth_refresh_token';

  Future<void> _persistRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      // Browser refresh tokens live exclusively in an HttpOnly cookie.
      // Also remove any token left by the legacy web implementation.
      await prefs.remove(_refreshTokenStorageKey);
      return;
    }

    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await prefs.setString(_refreshTokenStorageKey, _refreshToken!);
    } else {
      await prefs.remove(_refreshTokenStorageKey);
    }
  }

  Future<String?> _restoreRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      // Never expose or restore a browser refresh token to Dart.
      await prefs.remove(_refreshTokenStorageKey);
      return null;
    }

    return prefs.getString(_refreshTokenStorageKey);
  }

  Future<void> _clearPersistedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenStorageKey);
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
      final location =
          isEmail ? await GeolocationService.detectCountryByIP() : null;
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        kIsWeb ? '/auth/web/register/' : '/auth/register/',
        data: {
          if (isEmail) 'email': normalizedIdentifier,
          if (!isEmail) 'phone': normalizedIdentifier,
          if (location?['countryCode'] != null)
            'country_code': location!['countryCode'],
          'password': password,
          'firstname': firstname,
          'lastname': lastname,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data!;
        final access = data['access'] as String?;
        final refresh = kIsWeb ? null : data['refresh'] as String?;

        if (access != null) {
          _setBearerToken(access);
        }

        _refreshToken = refresh;
        await _persistRefreshToken();
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
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        kIsWeb ? '/auth/web/login/' : '/auth/login/',
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
        _refreshToken = kIsWeb ? null : data['refresh'] as String?;
        await _persistRefreshToken();
        _hasActiveSubscription = data['has_active_subscription'] == true;

        if (_accessToken != null) {
          _setBearerToken(_accessToken!);
          final profileLoaded = await _loadUserProfile();

          return {
            'success': profileLoaded,
            'statusCode': 200,
            'message':
                profileLoaded
                    ? 'Connexion réussie'
                    : 'Erreur lors du chargement du profil',
          };
        }
      }

      return {
        'success': false,
        'statusCode': response.statusCode ?? 500,
        'message': _getErrorMessageFromStatusCode(response.statusCode),
      };
    } on DioException catch (e) {
      // Avoid printing Dio's verbose exception (and browser internals) for an
      // expected authentication failure. Keep only safe diagnostic metadata.
      if (e.response == null) {
        debugPrint('Login network failure (${e.type.name})');
      }

      // Gestion spécifique des erreurs Dio
      final statusCode = e.response?.statusCode;
      final errorMessage =
          _apiErrorMessage(e.response?.data) ??
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
        'dioError': e.message,
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
        'message': 'Erreur inattendue lors de la connexion',
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiClient.dio.post<Map<String, dynamic>>(
        '/auth/password/change/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) {
          throw StateError(detail);
        }

        final errors = data['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              throw StateError(value.first.toString());
            }
          }
        }
      }

      throw StateError(
        'Impossible de modifier le mot de passe pour le moment.',
      );
    }
  }

  /// Charge le profil utilisateur connecté
  Future<bool> _loadUserProfile() async {
    if (_accessToken == null) return false;

    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/auth/me/',
      );
      final data = response.data;

      if (data != null) {
        _accountPhone = data['phone']?.toString();
        _hasActiveSubscription = data['has_active_subscription'] == true;

        final userData = Map<String, dynamic>.from(data)
          ..remove('has_active_subscription');

        _currentUser =
            apiClient.serializers.deserialize(
                  userData,
                  specifiedType: const FullType(User),
                )
                as User;

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

  /// Reloads the authenticated user after an account setting was changed.
  Future<bool> refreshCurrentUser() => _loadUserProfile();

  /// Updates personal information through the endpoint dedicated to account
  /// data. In particular, a phone-created account must send its original
  /// phone number when adding its first email address.
  Future<void> updatePersonalInfo({
    String? email,
    String? phone,
    String? countryCode,
  }) async {
    await apiClient.dio.patch<Map<String, dynamic>>(
      '/auth/personal-info/',
      data: {
        if (email != null) 'email': email.trim().toLowerCase(),
        if (phone != null) 'phone': phone,
        if (countryCode != null) 'country_code': countryCode,
      },
    );
    await _loadUserProfile();
  }

  /// Rafraîchir le token
  Future<bool> refreshAuthToken() async {
    try {
      if (kIsWeb) {
        final response = await apiClient.dio.post<Map<String, dynamic>>(
          '/auth/web/refresh/',
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        final access = response.data?['access'] as String?;

        if (response.statusCode == 200 && access != null && access.isNotEmpty) {
          _accessToken = access;
          _refreshToken = null;
          _setBearerToken(access);
          await _persistRefreshToken();
          notifyListeners();
          return true;
        }

        return false;
      }

      if (_refreshToken == null || _refreshToken!.isEmpty) {
        return false;
      }

      final refreshRequest = TokenRefresh((b) => b..refresh = _refreshToken!);
      final tokenResponse = await apiClient.getAuthApi().authTokenRefreshCreate(
        data: refreshRequest,
      );

      if (tokenResponse.data?.access != null) {
        _accessToken = tokenResponse.data!.access;

        _refreshToken = tokenResponse.data!.refresh;

        _setBearerToken(_accessToken!);
        await _persistRefreshToken();
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
      if (kIsWeb) {
        await apiClient.dio.post(
          '/auth/web/logout/',
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      } else if (_accessToken != null && _refreshToken != null) {
        await apiClient.dio.post(
          '/auth/logout/',
          data: {'refresh': _refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      }
    } catch (e) {
      debugPrint('Logout API failed: $e');
      // Local logout must still complete if the API is unavailable.
    } finally {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      await _clearPersistedAuth();
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
      await _clearPersistedAuth();
      _hasActiveSubscription = false;
      apiClient.dio.options.headers['Authorization'] = '';
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    try {
      if (_accessToken == null) {
        if (kIsWeb) {
          // Remove any legacy browser refresh token before using the
          // HttpOnly-cookie session.
          await _clearPersistedAuth();

          final refreshed = await refreshAuthToken();

          if (!refreshed) {
            _refreshToken = null;
            return false;
          }
        } else {
          _refreshToken ??= await _restoreRefreshToken();

          if (_refreshToken == null || _refreshToken!.isEmpty) {
            return false;
          }

          final refreshed = await refreshAuthToken();

          if (!refreshed) {
            await _clearPersistedAuth();
            _refreshToken = null;
            return false;
          }
        }
      }

      return await _loadUserProfile();
    } catch (_) {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      await _clearPersistedAuth();
      _hasActiveSubscription = false;
      apiClient.dio.options.headers['Authorization'] = '';
      notifyListeners();
      return false;
    }
  }
}
