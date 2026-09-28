class ProducerNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  const ProducerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory ProducerNotification.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    final type = rawType is Map ? rawType['name']?.toString() : rawType;
    final rawData = json['data'];

    return ProducerNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: type?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
    );
  }
}

class ProducerNotificationInbox {
  final List<ProducerNotification> notifications;
  final int unreadCount;

  const ProducerNotificationInbox({
    required this.notifications,
    required this.unreadCount,
  });
}
