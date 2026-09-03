import 'dart:convert';

import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String baseUrl = 'https://api.ekeflicks.com';

  final BrowserClient _client = BrowserClient()..withCredentials = true;

  String? _accessToken;

  String? get accessToken => _accessToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> _headers({bool authenticated = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated && hasAccessToken) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  Future<http.Response> get(String path, {bool authenticated = false}) {
    return _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(authenticated: authenticated),
    );
  }

  Future<http.Response> getBytes(String path, {bool authenticated = false}) {
    return _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(authenticated: authenticated),
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(authenticated: authenticated),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _client.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(authenticated: authenticated),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
  }

  dynamic decode(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  String errorMessage(
    http.Response response, {
    String fallback = 'Une erreur est survenue.',
  }) {
    final data = decode(response);
    final message = _extractErrorMessage(data);

    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }

    return fallback;
  }

  String? _extractErrorMessage(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    if (value is List) {
      for (final item in value) {
        final message = _extractErrorMessage(item);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      return null;
    }

    if (value is Map) {
      const priorityKeys = <String>[
        'detail',
        'non_field_errors',
        'email',
        'phone',
        'password',
        'company_name',
        'legal_name',
        'legal_form',
        'registration_number',
        'country_code',
        'address',
        'city',
        'representative_name',
        'representative_role',
      ];

      for (final key in priorityKeys) {
        if (value.containsKey(key)) {
          final message = _extractErrorMessage(value[key]);
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      }

      for (final entry in value.entries) {
        final message = _extractErrorMessage(entry.value);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }

    return null;
  }
}
