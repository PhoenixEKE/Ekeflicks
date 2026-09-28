import 'package:plateforme_producteurs/models/producer_notification.dart';
import 'package:plateforme_producteurs/services/api_client.dart';

class ProducerNotificationService {
  ProducerNotificationService._();

  static final ProducerNotificationService instance =
      ProducerNotificationService._();

  final ApiClient _api = ApiClient.instance;

  Future<ProducerNotificationInbox> getInbox() async {
    final responses = await Future.wait([
      _api.get(
        '/api/v1/notifications/?ordering=-created_at',
        authenticated: true,
      ),
      _api.get(
        '/api/v1/notifications/?is_read=false&ordering=-created_at',
        authenticated: true,
      ),
    ]);

    for (final response in responses) {
      if (response.statusCode != 200) {
        throw ApiException(
          _api.errorMessage(
            response,
            fallback: 'Impossible de charger les notifications.',
          ),
          statusCode: response.statusCode,
        );
      }
    }

    final allPage = _parsePage(_api.decode(responses[0]));
    final unreadPage = _parsePage(_api.decode(responses[1]));
    return ProducerNotificationInbox(
      notifications: allPage.notifications,
      unreadCount: unreadPage.count,
    );
  }

  Future<void> markRead(String id) async {
    final response = await _api.post(
      '/api/v1/notifications/${Uri.encodeComponent(id)}/mark-read/',
      authenticated: true,
    );
    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de marquer cette notification comme lue.',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> markAllRead() async {
    final response = await _api.post(
      '/api/v1/notifications/mark-all-read/',
      authenticated: true,
    );
    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de marquer les notifications comme lues.',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  _NotificationPage _parsePage(dynamic payload) {
    if (payload is List) {
      final items = payload
          .whereType<Map>()
          .map((item) => ProducerNotification.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
      return _NotificationPage(items, items.where((item) => !item.isRead).length);
    }

    if (payload is Map) {
      final rawItems = payload['results'];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => ProducerNotification.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : <ProducerNotification>[];
      final count = int.tryParse(payload['count']?.toString() ?? '') ??
          items.where((item) => !item.isRead).length;
      return _NotificationPage(items, count);
    }

    throw const ApiException('Réponse Notifications invalide.');
  }
}

class _NotificationPage {
  final List<ProducerNotification> notifications;
  final int count;

  const _NotificationPage(this.notifications, this.count);
}
