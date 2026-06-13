import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/offers_repository.dart';
import '../../domain/offer.dart';

/// État de la liste paginée d'offres (avec recherche + filtres + load-more).
class OffersListState {
  final List<Offer> offers;
  final bool isLoading; // premier chargement / refresh
  final bool isLoadingMore; // pagination
  final bool hasMore;
  final int page;
  final String? error;
  final OfferFilters filters;

  const OffersListState({
    this.offers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.filters = const OfferFilters(),
  });

  OffersListState copyWith({
    List<Offer>? offers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    OfferFilters? filters,
    bool clearError = false,
  }) {
    return OffersListState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class OffersNotifier extends Notifier<OffersListState> {
  late final OffersRepository _repo;

  @override
  OffersListState build() {
    _repo = ref.read(offersRepositoryProvider);
    // Chargement initial déclenché par l'écran via refresh().
    return const OffersListState();
  }

  /// (Re)charge depuis la page 1. Appelé au démarrage, au pull-to-refresh,
  /// et à chaque changement de recherche/filtre.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.fetchOffers(page: 1, filters: state.filters);
      state = state.copyWith(
        offers: res.data,
        page: 1,
        hasMore: res.hasNextPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Charge la page suivante (pagination / scroll infini).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.page + 1;
      final res = await _repo.fetchOffers(page: next, filters: state.filters);
      state = state.copyWith(
        offers: [...state.offers, ...res.data],
        page: next,
        hasMore: res.hasNextPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Met à jour la recherche texte et recharge.
  Future<void> search(String query) async {
    state = state.copyWith(filters: state.filters.copyWith(search: query));
    await refresh();
  }

  /// Applique de nouveaux filtres et recharge.
  Future<void> applyFilters(OfferFilters filters) async {
    state = state.copyWith(filters: filters);
    await refresh();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(filters: OfferFilters(search: state.filters.search));
    await refresh();
  }
}

final offersProvider =
    NotifierProvider<OffersNotifier, OffersListState>(OffersNotifier.new);

/// Détail d'une offre (chargé à la demande).
final offerDetailProvider = FutureProvider.family<Offer, String>((ref, id) async {
  final repo = ref.read(offersRepositoryProvider);
  return repo.fetchOne(id);
});
