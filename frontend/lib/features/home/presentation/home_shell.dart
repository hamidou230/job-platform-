import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/domain/user.dart';
import '../../offers/presentation/screens/offers_list_screen.dart';
import '../../offers/presentation/screens/company_offers_screen.dart';
import '../../favorites/presentation/screens/favorites_screen.dart';
import '../../applications/presentation/screens/my_applications_screen.dart';
import '../../notifications/presentation/screens/notifications_screen.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../admin/presentation/screens/admin_dashboard_screen.dart';

/// Coquille principale avec barre de navigation adaptée au rôle.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Charge le compteur de notifications dès l'ouverture (badge).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider.select((s) => s.user?.role)) ?? UserRole.unknown;
    final unread = ref.watch(notificationsProvider.select((s) => s.unreadCount));

    final tabs = _tabsForRole(role, unread);
    // Garde l'index dans les bornes si le rôle change.
    if (_index >= tabs.length) _index = 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: t.badgeCount > 0
                      ? Badge(label: Text('${t.badgeCount}'), child: Icon(t.icon))
                      : Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  List<_TabDef> _tabsForRole(UserRole role, int unread) {
    switch (role) {
      case UserRole.student:
        return [
          _TabDef('Offres', Icons.work_outline, Icons.work, const OffersListScreen()),
          _TabDef('Favoris', Icons.favorite_border, Icons.favorite, const FavoritesScreen()),
          _TabDef('Candidatures', Icons.description_outlined, Icons.description,
              const MyApplicationsScreen()),
          _TabDef('Alertes', Icons.notifications_outlined, Icons.notifications,
              const NotificationsScreen(),
              badgeCount: unread),
          _TabDef('Profil', Icons.person_outline, Icons.person, const ProfileScreen()),
        ];
      case UserRole.company:
        return [
          _TabDef('Mes offres', Icons.work_outline, Icons.work, const CompanyOffersScreen()),
          _TabDef('Alertes', Icons.notifications_outlined, Icons.notifications,
              const NotificationsScreen(),
              badgeCount: unread),
          _TabDef('Profil', Icons.person_outline, Icons.person, const ProfileScreen()),
        ];
      case UserRole.admin:
        return [
          _TabDef('Dashboard', Icons.dashboard_outlined, Icons.dashboard,
              const AdminDashboardScreen()),
          _TabDef('Profil', Icons.person_outline, Icons.person, const ProfileScreen()),
        ];
      default:
        return [
          _TabDef('Offres', Icons.work_outline, Icons.work, const OffersListScreen()),
          _TabDef('Profil', Icons.person_outline, Icons.person, const ProfileScreen()),
        ];
    }
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final int badgeCount;
  _TabDef(this.label, this.icon, this.selectedIcon, this.screen, {this.badgeCount = 0});
}
