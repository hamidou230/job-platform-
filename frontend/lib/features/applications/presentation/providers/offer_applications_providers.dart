import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/applications_repository.dart';
import '../../domain/application.dart';

/// Candidatures reçues pour une offre donnée (côté entreprise).
final offerApplicationsProvider =
    FutureProvider.family<List<Application>, String>((ref, offerId) async {
  final repo = ref.read(applicationsRepositoryProvider);
  final res = await repo.forOffer(offerId, page: 1);
  return res.data;
});

/// Action de mise à jour de statut (acceptée/refusée/examinée).
final updateApplicationStatusProvider =
    Provider<Future<void> Function(String, String, String)>((ref) {
  final repo = ref.read(applicationsRepositoryProvider);
  return (String applicationId, String status, String offerId) async {
    await repo.updateStatus(applicationId, status);
    ref.invalidate(offerApplicationsProvider(offerId));
  };
});
