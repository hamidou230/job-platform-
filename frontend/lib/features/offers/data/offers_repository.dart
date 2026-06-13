import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/paginated.dart';
import '../domain/offer.dart';

/// Filtres de recherche d'offres (mappés vers les query params de l'API).
class OfferFilters {
  final String? search;
  final String? type; // INTERNSHIP | JOB | ALTERNANCE | PART_TIME
  final String? location;
  final bool? isRemote;
  final String? experienceLevel;
  final int? salaryMin;
  final String? skills;

  const OfferFilters({
    this.search,
    this.type,
    this.location,
    this.isRemote,
    this.experienceLevel,
    this.salaryMin,
    this.skills,
  });

  OfferFilters copyWith({
    String? search,
    String? type,
    String? location,
    bool? isRemote,
    String? experienceLevel,
    int? salaryMin,
    String? skills,
    bool clearType = false,
    bool clearRemote = false,
    bool clearExperience = false,
  }) {
    return OfferFilters(
      search: search ?? this.search,
      type: clearType ? null : (type ?? this.type),
      location: location ?? this.location,
      isRemote: clearRemote ? null : (isRemote ?? this.isRemote),
      experienceLevel: clearExperience ? null : (experienceLevel ?? this.experienceLevel),
      salaryMin: salaryMin ?? this.salaryMin,
      skills: skills ?? this.skills,
    );
  }

  Map<String, dynamic> toQuery() => {
        if (search != null && search!.isNotEmpty) 'search': search,
        if (type != null) 'type': type,
        if (location != null && location!.isNotEmpty) 'location': location,
        if (isRemote != null) 'isRemote': isRemote,
        if (experienceLevel != null) 'experienceLevel': experienceLevel,
        if (salaryMin != null) 'salaryMin': salaryMin,
        if (skills != null && skills!.isNotEmpty) 'skills': skills,
      };

  bool get hasActiveFilters =>
      type != null || isRemote != null || experienceLevel != null || (location?.isNotEmpty ?? false);
}

class OffersRepository {
  final Dio _dio;
  OffersRepository(this._dio);

  /// Liste paginée + recherche + filtres (offres publiques OPEN).
  Future<Paginated<Offer>> fetchOffers({
    required int page,
    int limit = 10,
    OfferFilters filters = const OfferFilters(),
  }) async {
    try {
      final res = await _dio.get('/offers', queryParameters: {
        'page': page,
        'limit': limit,
        ...filters.toQuery(),
      });
      return Paginated.fromJson(res.data, (j) => Offer.fromJson(j));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Offer> fetchOne(String id) async {
    try {
      final res = await _dio.get('/offers/$id');
      return Offer.fromJson(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Offres publiées par l'entreprise connectée.
  Future<Paginated<Offer>> fetchMyOffers({required int page, int limit = 10}) async {
    try {
      final res = await _dio.get('/offers/mine', queryParameters: {'page': page, 'limit': limit});
      return Paginated.fromJson(res.data, (j) => Offer.fromJson(j));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Offer> createOffer(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/offers', data: body);
      return Offer.fromJson(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return OffersRepository(dio);
});
