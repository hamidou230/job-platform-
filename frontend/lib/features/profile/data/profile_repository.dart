import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  Future<void> updateStudent(Map<String, dynamic> body) async {
    try {
      await _dio.patch('/students/me', data: body);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> updateCompany(Map<String, dynamic> body) async {
    try {
      await _dio.patch('/companies/me', data: body);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<String> uploadAvatar({required String filePath, required String fileName, required bool isCompany}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final endpoint = isCompany ? '/companies/me/logo' : '/students/me/avatar';
      final res = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return (res.data['avatarUrl'] ?? res.data['logoUrl']) as String;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Upload du CV (PDF/DOC/DOCX) en multipart vers POST /students/me/cv.
  /// Renvoie l'URL relative du CV stockée côté serveur (ex: /uploads/cv/cv-123.pdf).
  Future<String> uploadCv({required String filePath, required String fileName}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final res = await _dio.post(
        '/students/me/cv',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data['cvUrl'] as String;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return ProfileRepository(dio);
});
