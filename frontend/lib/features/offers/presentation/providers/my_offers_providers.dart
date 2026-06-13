import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/offers_repository.dart';
import '../../domain/offer.dart';

/// Offres publiées par l'entreprise connectée.
class MyOffersState {
  final List<Offer> offers;
  final bool isLoading;
  final String? error;
  const MyOffersState({this.offers = const [], this.isLoading = false, this.error});

  MyOffersState copyWith({List<Offer>? offers, bool? isLoading, String? error, bool clearError = false}) {
    return MyOffersState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MyOffersNotifier extends Notifier<MyOffersState> {
  late final OffersRepository _repo;

  @override
  MyOffersState build() {
    _repo = ref.read(offersRepositoryProvider);
    return const MyOffersState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.fetchMyOffers(page: 1);
      state = state.copyWith(offers: res.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crée une offre puis rafraîchit. Renvoie null si OK, sinon le message d'erreur.
  Future<String?> create(Map<String, dynamic> body) async {
    try {
      await _repo.createOffer(body);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final myOffersProvider =
    NotifierProvider<MyOffersNotifier, MyOffersState>(MyOffersNotifier.new);
