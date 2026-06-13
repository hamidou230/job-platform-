import 'package:dio/dio.dart';
import '../errors/failure.dart';

/// Convertit une DioException en Failure lisible (messages en français).
Failure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const Failure('Le serveur met trop de temps à répondre.');
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Une erreur est survenue.';
      if (data is Map && data['message'] != null) {
        final m = data['message'];
        message = m is List ? m.join('\n') : m.toString();
      }
      if (status == 401) return UnauthorizedFailure(message);
      return Failure(message, statusCode: status);
    case DioExceptionType.cancel:
      return const Failure('Requête annulée.');
    default:
      return const Failure('Erreur réseau inattendue.');
  }
}
