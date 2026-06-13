import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/paginated.dart';
import '../domain/admin_stats.dart';

class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  Future<AdminStats> stats() async {
    try {
      final res = await _dio.get('/admin/stats');
      return AdminStats.fromJson(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Paginated<AdminUser>> users({required int page, int limit = 20}) async {
    try {
      final res = await _dio.get('/admin/users', queryParameters: {'page': page, 'limit': limit});
      return Paginated.fromJson(res.data, (j) => AdminUser.fromJson(j));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> toggleActive(String userId) async {
    try {
      await _dio.patch('/admin/users/$userId/toggle-active');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return AdminRepository(dio);
});
