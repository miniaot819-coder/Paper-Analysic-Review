import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/research_notification.dart';
import '../viewmodels/notification_center_view_model.dart';

class NotificationCenterCard extends StatelessWidget {
  const NotificationCenterCard({required this.viewModel, super.key});

  final NotificationCenterViewModel viewModel;

  Future<void> _copyToken(BuildContext context) async {
    final token = viewModel.token;
    if (token == null) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FCM registration token copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      key: const Key('notification_center'),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Notification Center',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (viewModel.unreadCount > 0)
                  Badge.count(
                    key: const Key('notification_unread_count'),
                    count: viewModel.unreadCount,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _PermissionPanel(viewModel: viewModel, onCopyToken: _copyToken),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.errorMessage!,
                      key: const Key('notification_error'),
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      key: const Key(
                        'retry_notification_initialization_button',
                      ),
                      onPressed: viewModel.isInitializing
                          ? null
                          : () => unawaited(viewModel.retryInitialization()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry notification setup'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Research updates',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (viewModel.unreadCount > 0)
                  TextButton(
                    key: const Key('mark_all_notifications_read'),
                    onPressed: () => unawaited(viewModel.markAllAsRead()),
                    child: const Text('Mark all as read'),
                  ),
                if (viewModel.notifications.isNotEmpty)
                  IconButton(
                    key: const Key('clear_notifications'),
                    tooltip: 'Clear all',
                    onPressed: () => unawaited(viewModel.clearAll()),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
              ],
            ),
            if (viewModel.isInitializing && viewModel.notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (viewModel.notifications.isEmpty)
              const Padding(
                key: Key('notification_empty_state'),
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'No research notifications yet.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              ...viewModel.notifications.map(
                (notification) => _NotificationTile(
                  notification: notification,
                  onTap: () => unawaited(viewModel.markAsRead(notification.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({required this.viewModel, required this.onCopyToken});

  final NotificationCenterViewModel viewModel;
  final Future<void> Function(BuildContext context) onCopyToken;

  @override
  Widget build(BuildContext context) {
    final status = viewModel.authorizationStatus;
    final permitted = viewModel.hasPermission;
    final statusText = switch (status) {
      AuthorizationStatus.authorized => 'Notifications are enabled',
      AuthorizationStatus.provisional =>
        'Provisional notifications are enabled',
      AuthorizationStatus.denied => 'Notification permission is denied',
      AuthorizationStatus.notDetermined =>
        'Notification permission not granted',
    };

    return Container(
      key: const Key('notification_permission_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: permitted ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                permitted
                    ? Icons.check_circle_outline_rounded
                    : Icons.notifications_off_outlined,
                color: permitted
                    ? const Color(0xFF047857)
                    : const Color(0xFFC2410C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  key: const Key('notification_permission_status'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (!permitted) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('request_notification_permission_button'),
              onPressed: viewModel.isRequestingPermission
                  ? null
                  : () => unawaited(viewModel.requestPermission()),
              icon: viewModel.isRequestingPermission
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              label: Text(
                viewModel.isRequestingPermission
                    ? 'Requesting permission...'
                    : 'Enable notifications',
              ),
            ),
          ] else if (viewModel.token != null) ...[
            const SizedBox(height: 8),
            Text(
              'The FCM token is ready for a test message.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton.icon(
              key: const Key('copy_fcm_token_button'),
              onPressed: () => unawaited(onCopyToken(context)),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy test token'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final ResearchNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = notification.receivedAt.toLocal();
    final minute = time.minute.toString().padLeft(2, '0');
    final dateText =
        '${time.day}/${time.month}/${time.year} '
        '${time.hour}:$minute';

    return InkWell(
      key: Key('notification_${notification.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? const Color(0xFFF8FAFC)
              : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              notification.isRead
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(notification.body),
                  if (notification.topic != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Topic: ${notification.topic}',
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    dateText,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
