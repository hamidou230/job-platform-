import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_stats.dart';

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  return ref.read(adminRepositoryProvider).stats();
});

class AdminUsersState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;
  const AdminUsersState({this.users = const [], this.isLoading = false, this.error});

  AdminUsersState copyWith({List<AdminUser>? users, bool? isLoading, String? error, bool clearError = false}) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  late final AdminRepository _repo;

  @override
  AdminUsersState build() {
    _repo = ref.read(adminRepositoryProvider);
    return const AdminUsersState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.users(page: 1);
      state = state.copyWith(users: res.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggle(AdminUser user) async {
    // Optimiste
    final updated = state.users
        .map((u) => u.id == user.id
            ? AdminUser(
                id: u.id, email: u.email, role: u.role, isActive: !u.isActive, name: u.name)
            : u)
        .toList();
    state = state.copyWith(users: updated);
    try {
      await _repo.toggleActive(user.id);
    } catch (_) {
      await refresh();
    }
  }
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersState>(AdminUsersNotifier.new);
