import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/paginated.dart';
import '../domain/application.dart';

class ApplicationsRepository {
  final Dio _dio;
  ApplicationsRepository(this._dio);

  /// Postuler à une offre. Le CV du profil est utilisé par défaut côté backend
  /// si [cvUrl] n'est pas fourni.
  Future<Application> apply({
    required String offerId,
    String? coverLetter,
    String? cvUrl,
  }) async {
    try {
      final res = await _dio.post('/applications', data: {
        'offerId': offerId,
        if (coverLetter != null && coverLetter.isNotEmpty) 'coverLetter': coverLetter,
        if (cvUrl != null && cvUrl.isNotEmpty) 'cvUrl': cvUrl,
      });
      return Application.fromJson(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Candidatures de l'étudiant connecté.
  Future<Paginated<Application>> myApplications({required int page, int limit = 20}) async {
    try {
      final res =
          await _dio.get('/applications/mine', queryParameters: {'page': page, 'limit': limit});
      return Paginated.fromJson(res.data, (j) => Application.fromJson(j));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Candidatures reçues sur une offre (entreprise).
  Future<Paginated<Application>> forOffer(String offerId, {required int page, int limit = 20}) async {
    try {
      final res = await _dio
          .get('/applications/offer/$offerId', queryParameters: {'page': page, 'limit': limit});
      return Paginated.fromJson(res.data, (j) => Application.fromJson(j));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _dio.patch('/applications/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> withdraw(String id) async {
    try {
      await _dio.delete('/applications/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return ApplicationsRepository(dio);
});
