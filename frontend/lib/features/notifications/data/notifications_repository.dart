import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/paginated.dart';
import '../notification_model.dart';

class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

  /// Renvoie la page de notifications + le nombre de non-lues (champ "unreadCount").
  Future<(Paginated<AppNotification>, int)> list({required int page, int limit = 20}) async {
    try {
      final res =
          await _dio.get('/notifications', queryParameters: {'page': page, 'limit': limit});
      final paginated = Paginated.fromJson(res.data, (j) => AppNotification.fromJson(j));
      final unread = res.data['unreadCount'] ?? 0;
      return (paginated, unread as int);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return NotificationsRepository(dio);
});
