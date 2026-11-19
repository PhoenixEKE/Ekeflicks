import 'package:flutter_test/flutter_test.dart';
import 'package:app_ekeflicks/services/notification_service.dart';

void main() {
  test('parses notification preferences returned by the API', () {
    final preferences = NotificationPreferences.fromJson({
      'email_enabled': false,
      'push_enabled': true,
      'categories': {'security': true, 'catalog': false},
    });

    expect(preferences.emailEnabled, isFalse);
    expect(preferences.pushEnabled, isTrue);
    expect(preferences.categories['catalog'], isFalse);
  });

  test('parses an unread notification', () {
    final notification = AppNotification.fromJson({
      'id': 'notification-id',
      'title': 'Abonnement',
      'message': 'Votre abonnement est actif.',
      'is_read': false,
      'created_at': '2026-08-09T12:00:00Z',
    });

    expect(notification.id, 'notification-id');
    expect(notification.isRead, isFalse);
    expect(notification.createdAt, DateTime.utc(2026, 8, 9, 12));
  });
}
