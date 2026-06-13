import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/offer_applications_providers.dart';
import '../../domain/application.dart';

/// Vue entreprise : candidatures reçues pour une offre, avec actions de statut.
class OfferApplicationsScreen extends ConsumerWidget {
  final String offerId;
  final String offerTitle;
  const OfferApplicationsScreen({super.key, required this.offerId, required this.offerTitle});

  Color _statusColor(BuildContext context, String s) {
    final cs = Theme.of(context).colorScheme;
    switch (s) {
      case 'ACCEPTED': return Colors.green;
      case 'REJECTED': return cs.error;
      case 'REVIEWED': return Colors.orange;
      default: return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(offerApplicationsProvider(offerId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidatures'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(offerTitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(offerApplicationsProvider(offerId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (apps) {
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 72, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Aucune candidature reçue',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: apps.length,
            itemBuilder: (_, i) => _ApplicantCard(
              app: apps[i],
              offerId: offerId,
              statusColor: _statusColor(context, apps[i].status),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  final Application app;
  final String offerId;
  final Color statusColor;
  const _ApplicantCard({required this.app, required this.offerId, required this.statusColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final applicant = app.applicant;

    final cvUrl = app.cvUrl ?? applicant?.cvUrl;

    Future<void> openCv() async {
      if (cvUrl == null || cvUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun CV disponible pour ce candidat.')),
        );
        return;
      }
      // Le backend stocke un chemin relatif (/uploads/cv/xxx.pdf).
      // On reconstruit l'URL absolue en retirant le suffixe /api de la baseUrl.
      final rawUrl = cvUrl.startsWith('http')
          ? cvUrl
          : '${AppConstants.baseUrl.replaceFirst(RegExp(r'/api$'), '')}$cvUrl';
      final uri = Uri.tryParse(rawUrl);
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le CV.')),
          );
        }
      }
    }

    Future<void> setStatus(String status) async {
      final fn = ref.read(updateApplicationStatusProvider);
      await fn(app.id, status, offerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour')),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    (applicant?.fullName.isNotEmpty == true ? applicant!.fullName : '?')
                        .characters.first.toUpperCase(),
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(applicant?.fullName ?? 'Candidat',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (applicant?.university != null)
                        Text(applicant!.university!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(app.statusLabel,
                      style: TextStyle(
                          color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(app.coverLetter!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (cvUrl != null && cvUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: openCv,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Voir le CV'),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => setStatus('ACCEPTED'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setStatus('REJECTED'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Refuser'),
                ),
                TextButton.icon(
                  onPressed: () => setStatus('REVIEWED'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Examinée'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
