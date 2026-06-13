import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/my_offers_providers.dart';

class CompanyOffersScreen extends ConsumerStatefulWidget {
  const CompanyOffersScreen({super.key});
  @override
  ConsumerState<CompanyOffersScreen> createState() => _CompanyOffersScreenState();
}

class _CompanyOffersScreenState extends ConsumerState<CompanyOffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myOffersProvider.notifier).refresh();
    });
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'OPEN': return 'Ouverte';
      case 'CLOSED': return 'Fermée';
      case 'DRAFT': return 'Brouillon';
      default: return s;
    }
  }

  Color _statusColor(BuildContext context, String s) {
    switch (s) {
      case 'OPEN': return Colors.green;
      case 'CLOSED': return Theme.of(context).colorScheme.error;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myOffersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes offres')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/offers/create'),
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myOffersProvider.notifier).refresh(),
        child: state.isLoading && state.offers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.offers.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Icon(Icons.work_outline,
                          size: 72, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('Aucune offre publiée',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Appuyez sur « Publier » pour créer votre première offre.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: state.offers.length,
                    itemBuilder: (_, i) {
                      final o = state.offers[i];
                      final color = _statusColor(context, o.status);
                      return Card(
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(o.title,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_statusLabel(o.status),
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                Text(o.typeLabel, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${o.applicationsCount}',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text('reçues', style: theme.textTheme.labelSmall),
                            ],
                          ),
                          onTap: () => context.push('/offers/${o.id}/applications',
                              extra: o.title),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
