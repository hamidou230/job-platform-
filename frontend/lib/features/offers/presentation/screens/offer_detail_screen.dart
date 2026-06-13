import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offers_providers.dart';
import '../../domain/offer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/user.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../applications/presentation/providers/applications_providers.dart';

class OfferDetailScreen extends ConsumerWidget {
  final String offerId;
  const OfferDetailScreen({super.key, required this.offerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(offerDetailProvider(offerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'offre')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(offerDetailProvider(offerId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (offer) => _OfferDetailBody(offer: offer),
      ),
    );
  }
}

class _OfferDetailBody extends ConsumerWidget {
  final Offer offer;
  const _OfferDetailBody({required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final role = ref.watch(authProvider.select((s) => s.user?.role));
    final isStudent = role == UserRole.student;
    final isFav = ref.watch(favoritesProvider.select((s) => s.ids.contains(offer.id)));
    final hasApplied = ref.watch(myApplicationsProvider.select((s) => s.appliedOfferIds.contains(offer.id)));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      (offer.company?.name ?? '?').characters.first.toUpperCase(),
                      style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(offer.title,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (offer.company != null)
                          Text(offer.company!.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(context, Icons.work_outline, offer.typeLabel),
                  if (offer.isRemote) _infoChip(context, Icons.wifi, 'Télétravail'),
                  if (offer.location != null && offer.location!.isNotEmpty)
                    _infoChip(context, Icons.location_on_outlined, offer.location!),
                  _infoChip(context, Icons.payments_outlined, offer.salaryLabel),
                  _infoChip(context, Icons.badge_outlined, _expLabel(offer.experienceLevel)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(offer.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
              if (offer.skillList.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Compétences requises',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: offer.skillList
                      .map((s) => Chip(
                            label: Text(s),
                            backgroundColor: cs.secondaryContainer,
                            labelStyle: TextStyle(color: cs.onSecondaryContainer),
                          ))
                      .toList(),
                ),
              ],
              if (offer.deadline != null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Date limite : ${_fmtDate(offer.deadline!)}',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (isStudent) _buildStudentActions(context, ref, isFav, hasApplied),
      ],
    );
  }

  Widget _buildStudentActions(BuildContext context, WidgetRef ref, bool isFav, bool hasApplied) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            IconButton.filledTonal(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? cs.error : null),
              onPressed: () => ref.read(favoritesProvider.notifier).toggle(offer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: Icon(hasApplied ? Icons.check_circle : Icons.send),
                label: Text(hasApplied ? 'Déjà postulé' : 'Postuler'),
                onPressed: hasApplied ? null : () => _showApplySheet(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApplySheet(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final user = ref.read(authProvider).user;
    final hasCv = user?.student?.cvUrl != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            final theme = Theme.of(sheetContext);
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Postuler à « ${offer.title} »',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(hasCv ? Icons.check_circle : Icons.warning_amber,
                          size: 16,
                          color: hasCv ? Colors.green : theme.colorScheme.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hasCv
                              ? 'Votre CV enregistré sera joint automatiquement.'
                              : 'Aucun CV dans votre profil. Ajoutez-en un depuis l\'onglet Profil.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Lettre de motivation (optionnel)',
                      alignLabelWithHint: true,
                      hintText: 'Présentez-vous en quelques lignes...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              setSheet(() => submitting = true);
                              final err = await ref.read(myApplicationsProvider.notifier).apply(
                                    offerId: offer.id,
                                    coverLetter: controller.text.trim(),
                                  );
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err ?? 'Candidature envoyée ✅'),
                                    backgroundColor: err != null ? Theme.of(context).colorScheme.error : null,
                                  ),
                                );
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Envoyer ma candidature'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  static String _expLabel(String v) {
    switch (v) {
      case 'JUNIOR': return 'Junior';
      case 'INTERMEDIATE': return 'Intermédiaire';
      case 'SENIOR': return 'Senior';
      default: return v;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
