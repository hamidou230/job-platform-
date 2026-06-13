import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/favorites_repository.dart';
import '../../../offers/domain/offer.dart';

/// État des favoris : la liste des offres + l'ensemble des IDs favoris
/// (pour l'affichage instantané du cœur partout dans l'app).
class FavoritesState {
  final List<Offer> offers;
  final Set<String> ids;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.offers = const [],
    this.ids = const {},
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<Offer>? offers,
    Set<String>? ids,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FavoritesState(
      offers: offers ?? this.offers,
      ids: ids ?? this.ids,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  late final FavoritesRepository _repo;

  @override
  FavoritesState build() {
    _repo = ref.read(favoritesRepositoryProvider);
    return const FavoritesState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.list(page: 1);
      state = state.copyWith(
        offers: res.data,
        ids: res.data.map((o) => o.id).toSet(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  bool isFavorite(String offerId) => state.ids.contains(offerId);

  /// Bascule optimiste : on met à jour l'UI immédiatement, puis on confirme
  /// avec le serveur (et on annule en cas d'erreur).
  Future<void> toggle(Offer offer) async {
    final wasFav = state.ids.contains(offer.id);
    final newIds = Set<String>.from(state.ids);
    final newOffers = List<Offer>.from(state.offers);
    if (wasFav) {
      newIds.remove(offer.id);
      newOffers.removeWhere((o) => o.id == offer.id);
    } else {
      newIds.add(offer.id);
      newOffers.insert(0, offer);
    }
    state = state.copyWith(ids: newIds, offers: newOffers);

    try {
      final nowFav = await _repo.toggle(offer.id);
      // Réconcilie si le serveur diffère de l'optimisme local.
      if (nowFav != newIds.contains(offer.id)) {
        await refresh();
      }
    } catch (e) {
      // Rollback
      state = state.copyWith(
        ids: state.ids,
        error: e.toString(),
      );
      await refresh();
    }
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, FavoritesState>(FavoritesNotifier.new);
