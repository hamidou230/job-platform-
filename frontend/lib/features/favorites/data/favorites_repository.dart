import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/paginated.dart';
import '../../offers/domain/offer.dart';

class FavoritesRepository {
  final Dio _dio;
  FavoritesRepository(this._dio);

  /// Bascule un favori. Renvoie true si l'offre est désormais en favori.
  Future<bool> toggle(String offerId) async {
    try {
      final res = await _dio.post('/favorites/$offerId/toggle');
      return res.data['favorited'] == true;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Paginated<Offer>> list({required int page, int limit = 20}) async {
    try {
      final res = await _dio.get('/favorites', queryParameters: {'page': page, 'limit': limit});
      // Chaque favori contient { offer: {...} } -> on extrait l'offre.
      return Paginated.fromJson(res.data, (j) {
        final offerJson = j['offer'] as Map<String, dynamic>? ?? j;
        return Offer.fromJson(offerJson);
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return FavoritesRepository(dio);
});
