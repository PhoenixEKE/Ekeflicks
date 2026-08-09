import 'package:dio/dio.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.categories,
  });

  final bool emailEnabled;
  final bool pushEnabled;
  final Map<String, bool> categories;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        emailEnabled: json['email_enabled'] != false,
        pushEnabled: json['push_enabled'] != false,
        categories: (json['categories'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value == true),
        ),
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        isRead: json['is_read'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class NotificationService {
  NotificationService(this._dio);

  final Dio _dio;

  Future<List<AppNotification>> list() async {
    final response = await _dio.get<Object>('/notifications/');
    final body = response.data;
    final items = body is Map ? body['results'] : body;
    return items is List
        ? items.whereType<Map>().map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item))).toList()
        : const [];
  }

  Future<void> markRead(String id) => _dio.post<void>('/notifications/$id/mark-read/');
  Future<void> markAllRead() => _dio.post<void>('/notifications/mark-all-read/');

  Future<NotificationPreferences> preferences() async {
    final response = await _dio.get<Map<String, dynamic>>('/notifications/preferences/');
    return NotificationPreferences.fromJson(response.data ?? const {});
  }

  Future<NotificationPreferences> updatePreferences(Map<String, dynamic> data) async {
    final response = await _dio.patch<Map<String, dynamic>>('/notifications/preferences/', data: data);
    return NotificationPreferences.fromJson(response.data ?? const {});
  }

  Future<void> unsubscribe(String token) =>
      _dio.post<void>('/notification-unsubscribe/', data: {'token': token});
}
