import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_providers.dart';
import '../../notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).refresh();
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'APPLICATION': return Icons.description_outlined;
      case 'OFFER': return Icons.work_outline;
      default: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Icon(Icons.notifications_none,
                          size: 72, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('Aucune notification',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final AppNotification n = state.items[i];
                      final cs = theme.colorScheme;
                      return ListTile(
                        onTap: n.isRead
                            ? null
                            : () => ref.read(notificationsProvider.notifier).markRead(n.id),
                        leading: CircleAvatar(
                          backgroundColor:
                              n.isRead ? cs.surfaceContainerHighest : cs.primaryContainer,
                          child: Icon(_iconFor(n.type),
                              color: n.isRead ? cs.onSurfaceVariant : cs.onPrimaryContainer),
                        ),
                        title: Text(n.title,
                            style: TextStyle(
                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(n.message),
                        trailing: n.isRead
                            ? null
                            : Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                      );
                    },
                  ),
      ),
    );
  }
}
