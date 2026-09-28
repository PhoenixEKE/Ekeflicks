import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/models/producer_notification.dart';
import 'package:plateforme_producteurs/services/producer_notification_service.dart';
import 'package:plateforme_producteurs/widgets/producer_modal_shell.dart';

class ProducerNotificationsDialog extends StatefulWidget {
  const ProducerNotificationsDialog({super.key, required this.onChanged});

  final Future<void> Function(ProducerNotificationInbox inbox) onChanged;

  @override
  State<ProducerNotificationsDialog> createState() =>
      _ProducerNotificationsDialogState();
}

class _ProducerNotificationsDialogState
    extends State<ProducerNotificationsDialog> {
  ProducerNotificationInbox? _inbox;
  Object? _error;
  bool _loading = true;
  bool _markingAll = false;
  String? _markingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inbox = await ProducerNotificationService.instance.getInbox();
      if (!mounted) return;
      setState(() {
        _inbox = inbox;
        _loading = false;
      });
      await widget.onChanged(inbox);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _markRead(ProducerNotification notification) async {
    if (_markingId != null || notification.isRead) return;
    setState(() => _markingId = notification.id);
    try {
      await ProducerNotificationService.instance.markRead(notification.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _markingId = null);
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || (_inbox?.unreadCount ?? 0) == 0) return;
    setState(() => _markingAll = true);
    try {
      await ProducerNotificationService.instance.markAllRead();
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProducerModalShell(
      title: l10n.notificationsTitle,
      maxWidth: 680,
      maxHeight: 680,
      actions: [
        if ((_inbox?.unreadCount ?? 0) > 0)
          TextButton.icon(
            onPressed: _markingAll ? null : _markAllRead,
            icon: _markingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all_rounded),
            label: Text(l10n.notificationsMarkAllRead),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close, style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      child: SizedBox(
        width: double.infinity,
        child: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading && _inbox == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _inbox == null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        message: l10n.notificationsLoadError,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }

    final notifications = _inbox?.notifications ?? const [];
    if (notifications.isEmpty) {
      return _MessageState(
        icon: Icons.notifications_none_rounded,
        message: l10n.notificationsEmpty,
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.notificationsUpdateError,
              style: AppTheme.textCaption.copyWith(color: AppTheme.error),
            ),
          ),
        if (_loading)
          const LinearProgressIndicator(minHeight: 2),
        for (final notification in notifications)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: notification.isRead
                ? AppTheme.cardBackground
                : AppTheme.primary.withValues(alpha: 0.10),
            child: ListTile(
              onTap: notification.isRead
                  ? null
                  : () => _markRead(notification),
              leading: Icon(
                _iconFor(notification.type),
                color: notification.isRead
                    ? AppTheme.textSecondary
                    : AppTheme.primary,
              ),
              title: Text(
                notification.title.isEmpty
                    ? notification.type
                    : notification.title,
                style: AppTheme.textBody.copyWith(
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.w700,
                ),
              ),
              subtitle: notification.message.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(notification.message),
                    ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!notification.isRead)
                    const Icon(
                      Icons.circle,
                      size: 9,
                      color: AppTheme.primary,
                    ),
                  if (notification.createdAt != null)
                    Text(
                      DateFormat.Md(locale)
                          .add_Hm()
                          .format(notification.createdAt!.toLocal()),
                      style: AppTheme.textCaption,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('video_') || type.startsWith('content_')) {
      return Icons.video_library_outlined;
    }
    if (type.contains('payout') || type.contains('payment')) {
      return Icons.payments_outlined;
    }
    if (type.contains('account') || type.contains('profile')) {
      return Icons.person_outline_rounded;
    }
    return Icons.notifications_outlined;
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: AppTheme.textBody),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
