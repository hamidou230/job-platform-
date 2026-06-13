import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/offer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/user.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';

/// Carte d'offre réutilisable (liste, favoris, recherche).
class OfferCard extends ConsumerWidget {
  final Offer offer;
  const OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final role = ref.watch(authProvider.select((s) => s.user?.role));
    final isStudent = role == UserRole.student;
    final isFav = ref.watch(favoritesProvider.select((s) => s.ids.contains(offer.id)));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/offer/${offer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      (offer.company?.name ?? '?').characters.first.toUpperCase(),
                      style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(offer.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (offer.company != null)
                          Text(offer.company!.name,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (isStudent)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? cs.error : cs.onSurfaceVariant),
                      onPressed: () => ref.read(favoritesProvider.notifier).toggle(offer),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(context, Icons.work_outline, offer.typeLabel, cs.secondaryContainer,
                      cs.onSecondaryContainer),
                  if (offer.isRemote)
                    _chip(context, Icons.wifi, 'Télétravail', cs.tertiaryContainer,
                        cs.onTertiaryContainer),
                  if (offer.location != null && offer.location!.isNotEmpty)
                    _chip(context, Icons.location_on_outlined, offer.location!,
                        cs.surfaceContainerHighest, cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(offer.salaryLabel,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (offer.applicationsCount > 0)
                    Text('${offer.applicationsCount} candidature(s)',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
