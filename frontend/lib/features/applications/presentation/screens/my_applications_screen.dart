import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/applications_providers.dart';
import '../../domain/application.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});
  @override
  ConsumerState<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myApplicationsProvider.notifier).refresh();
    });
  }

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'ACCEPTED': return Colors.green;
      case 'REJECTED': return cs.error;
      case 'REVIEWED': return Colors.orange;
      default: return cs.onSurfaceVariant; // PENDING
    }
  }

  Future<void> _confirmWithdraw(Application app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer la candidature ?'),
        content: Text('Votre candidature à « ${app.offer?.title ?? 'cette offre'} » sera supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(myApplicationsProvider.notifier).withdraw(app.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myApplicationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes candidatures')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myApplicationsProvider.notifier).refresh(),
        child: state.isLoading && state.applications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.applications.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Icon(Icons.description_outlined,
                          size: 72, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('Aucune candidature',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Postulez à une offre pour la suivre ici.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: state.applications.length,
                    itemBuilder: (_, i) {
                      final app = state.applications[i];
                      final color = _statusColor(context, app.status);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(app.offer?.title ?? 'Offre',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (app.offer?.company != null) Text(app.offer!.company!.name),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(app.statusLabel,
                                      style: TextStyle(
                                          color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'view' && app.offer != null) {
                                context.push('/offer/${app.offer!.id}');
                              } else if (v == 'withdraw') {
                                _confirmWithdraw(app);
                              }
                            },
                            itemBuilder: (_) => [
                              if (app.offer != null)
                                const PopupMenuItem(value: 'view', child: Text('Voir l\'offre')),
                              const PopupMenuItem(value: 'withdraw', child: Text('Retirer')),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
