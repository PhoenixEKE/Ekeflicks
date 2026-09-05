import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _notifications;

  NotificationService get _service =>
      NotificationService(context.read<ProfileProvider>().apiClient.dio);

  @override
  void initState() {
    super.initState();
    _notifications = Future.microtask(_service.list);
  }

  void _reload() => setState(() => _notifications = _service.list());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        IconButton(
          tooltip: 'Tout marquer comme lu',
          icon: const Icon(Icons.done_all),
          onPressed: () async {
            await _service.markAllRead();
            _reload();
          },
        ),
        IconButton(
          tooltip: 'Préférences',
          icon: const Icon(Icons.tune),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesPage(),
                ),
              ),
        ),
      ],
    ),
    body: FutureBuilder<List<AppNotification>>(
      future: _notifications,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Impossible de charger les notifications.\n${snapshot.error}',
            ),
          );
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('Vous n’avez aucune notification.'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(
                  item.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight:
                        item.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(item.message),
                trailing:
                    item.createdAt == null
                        ? null
                        : Text(
                          '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year}',
                        ),
                onTap:
                    item.isRead
                        ? null
                        : () async {
                          await _service.markRead(item.id);
                          _reload();
                        },
              );
            },
          ),
        );
      },
    ),
  );
}

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});
  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  NotificationPreferences? _preferences;
  bool _saving = false;
  NotificationService get _service =>
      NotificationService(context.read<ProfileProvider>().apiClient.dio);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final value = await _service.preferences();
      if (mounted) setState(() => _preferences = value);
    });
  }

  Future<void> _save(NotificationPreferences value) async {
    setState(() {
      _preferences = value;
      _saving = true;
    });
    try {
      final saved = await _service.updatePreferences({
        'email_enabled': value.emailEnabled,
        'push_enabled': value.pushEnabled,
        'categories': value.categories,
      });
      if (mounted) setState(() => _preferences = saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _preferences;
    return Scaffold(
      appBar: AppBar(title: const Text('Préférences de notification')),
      body:
          value == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  SwitchListTile(
                    title: const Text('Notifications dans l’application'),
                    subtitle: const Text(
                      'Alertes visibles dans votre centre de notifications',
                    ),
                    value: value.pushEnabled,
                    onChanged:
                        _saving
                            ? null
                            : (v) => _save(
                              NotificationPreferences(
                                emailEnabled: value.emailEnabled,
                                pushEnabled: v,
                                categories: value.categories,
                              ),
                            ),
                  ),
                  SwitchListTile(
                    title: const Text('E-mails transactionnels'),
                    subtitle: const Text(
                      'Vous pouvez vous désabonner des communications facultatives',
                    ),
                    value: value.emailEnabled,
                    onChanged:
                        _saving
                            ? null
                            : (v) => _save(
                              NotificationPreferences(
                                emailEnabled: v,
                                pushEnabled: value.pushEnabled,
                                categories: value.categories,
                              ),
                            ),
                  ),
                  const Divider(),
                  const ListTile(title: Text('Catégories')),
                  for (final entry
                      in const {
                        'security': 'Sécurité du compte',
                        'subscription': 'Abonnement et paiements',
                        'catalog': 'Nouveautés du catalogue',
                        'account': 'Informations du compte',
                      }.entries)
                    SwitchListTile(
                      title: Text(entry.value),
                      value: value.categories[entry.key] ?? true,
                      onChanged:
                          _saving
                              ? null
                              : (v) {
                                final categories = Map<String, bool>.from(
                                  value.categories,
                                )..[entry.key] = v;
                                _save(
                                  NotificationPreferences(
                                    emailEnabled: value.emailEnabled,
                                    pushEnabled: value.pushEnabled,
                                    categories: categories,
                                  ),
                                );
                              },
                    ),
                ],
              ),
    );
  }
}
