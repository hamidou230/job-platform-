import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/token_storage.dart';
import '../domain/user.dart';

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  AuthRepository(this._dio, this._tokenStorage);

  Future<AppUser> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return _handleAuth(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String role, // STUDENT | COMPANY
    String? firstName,
    String? lastName,
    String? companyName,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'role': role,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (companyName != null) 'companyName': companyName,
      });
      return _handleAuth(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AppUser?> me() async {
    final token = await _tokenStorage.read();
    if (token == null) return null;
    try {
      final res = await _dio.get('/auth/me');
      return AppUser.fromJson(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<AppUser> _handleAuth(Map<String, dynamic> data) async {
    await _tokenStorage.save(data['accessToken']);
    return AppUser.fromJson(data['user']);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  final storage = ref.read(tokenStorageProvider);
  return AuthRepository(dio, storage);
});
