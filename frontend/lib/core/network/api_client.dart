import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import 'token_storage.dart';

/// Client HTTP central basé sur Dio.
/// - Ajoute automatiquement le Bearer token.
/// - Configure timeouts et base URL.
class ApiClient {
  final Dio dio;
  ApiClient(this.dio);
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // Token invalide/expiré -> purge locale
        if (e.response?.statusCode == 401) {
          await tokenStorage.clear();
        }
        handler.next(e);
      },
    ),
  );

  return ApiClient(dio);
});
