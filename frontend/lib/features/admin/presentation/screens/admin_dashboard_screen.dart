import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_providers.dart';
import '../../domain/admin_stats.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          await ref.read(adminUsersProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('$e', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(adminStatsProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (stats) => _StatsGrid(stats: stats),
            ),
            const SizedBox(height: 24),
            Text('Utilisateurs',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const _UsersList(),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData('Utilisateurs', stats.users, Icons.people_outline, Colors.blue),
      _StatData('Étudiants', stats.students, Icons.school_outlined, Colors.teal),
      _StatData('Entreprises', stats.companies, Icons.business_outlined, Colors.indigo),
      _StatData('Offres', stats.offers, Icons.work_outline, Colors.deepPurple),
      _StatData('Offres ouvertes', stats.openOffers, Icons.lock_open_outlined, Colors.green),
      _StatData('Candidatures', stats.applications, Icons.description_outlined, Colors.orange),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => _StatCard(data: cards[i]),
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, color: data.color, size: 28),
            const Spacer(),
            Text('${data.value}',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(data.label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _UsersList extends ConsumerStatefulWidget {
  const _UsersList();
  @override
  ConsumerState<_UsersList> createState() => _UsersListState();
}

class _UsersListState extends ConsumerState<_UsersList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersProvider.notifier).refresh();
    });
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'STUDENT': return 'Étudiant';
      case 'COMPANY': return 'Entreprise';
      case 'ADMIN': return 'Admin';
      default: return r;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    if (state.isLoading && state.users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Aucun utilisateur')),
      );
    }
    return Column(
      children: state.users.map((u) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: u.isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
              child: Icon(u.isActive ? Icons.person : Icons.person_off,
                  color: u.isActive
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer),
            ),
            title: Text(u.name ?? u.email,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${_roleLabel(u.role)} • ${u.email}'),
            trailing: Switch(
              value: u.isActive,
              onChanged: u.role == 'ADMIN'
                  ? null
                  : (_) => ref.read(adminUsersProvider.notifier).toggle(u),
            ),
          ),
        );
      }).toList(),
    );
  }
}
