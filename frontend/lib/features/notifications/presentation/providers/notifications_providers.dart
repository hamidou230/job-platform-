import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';
import '../../notification_model.dart';

class NotificationsState {
  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  late final NotificationsRepository _repo;

  @override
  NotificationsState build() {
    _repo = ref.read(notificationsRepositoryProvider);
    return const NotificationsState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final (paginated, unread) = await _repo.list(page: 1);
      state = state.copyWith(items: paginated.data, unreadCount: unread, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    // Mise à jour optimiste
    final updated = state.items
        .map((n) => n.id == id
            ? AppNotification(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt)
            : n)
        .toList();
    final unread = updated.where((n) => !n.isRead).length;
    state = state.copyWith(items: updated, unreadCount: unread);
    try {
      await _repo.markRead(id);
    } catch (_) {
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    final updated = state.items
        .map((n) => AppNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt))
        .toList();
    state = state.copyWith(items: updated, unreadCount: 0);
    try {
      await _repo.markAllRead();
    } catch (_) {
      await refresh();
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);
