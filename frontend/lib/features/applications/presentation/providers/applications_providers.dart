import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/applications_repository.dart';
import '../../domain/application.dart';

class ApplicationsState {
  final List<Application> applications;
  final Set<String> appliedOfferIds; // pour désactiver "Postuler" si déjà fait
  final bool isLoading;
  final String? error;

  const ApplicationsState({
    this.applications = const [],
    this.appliedOfferIds = const {},
    this.isLoading = false,
    this.error,
  });

  ApplicationsState copyWith({
    List<Application>? applications,
    Set<String>? appliedOfferIds,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ApplicationsState(
      applications: applications ?? this.applications,
      appliedOfferIds: appliedOfferIds ?? this.appliedOfferIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MyApplicationsNotifier extends Notifier<ApplicationsState> {
  late final ApplicationsRepository _repo;

  @override
  ApplicationsState build() {
    _repo = ref.read(applicationsRepositoryProvider);
    return const ApplicationsState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.myApplications(page: 1);
      state = state.copyWith(
        applications: res.data,
        appliedOfferIds: res.data.map((a) => a.offer?.id).whereType<String>().toSet(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  bool hasApplied(String offerId) => state.appliedOfferIds.contains(offerId);

  /// Postule puis rafraîchit la liste. Renvoie null si OK, sinon le message d'erreur.
  Future<String?> apply({required String offerId, String? coverLetter, String? cvUrl}) async {
    try {
      await _repo.apply(offerId: offerId, coverLetter: coverLetter, cvUrl: cvUrl);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> withdraw(String id) async {
    try {
      await _repo.withdraw(id);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final myApplicationsProvider =
    NotifierProvider<MyApplicationsNotifier, ApplicationsState>(MyApplicationsNotifier.new);
