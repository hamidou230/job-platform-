import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;
  TokenStorage(this._storage);

  Future<void> save(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> read() => _storage.read(key: AppConstants.tokenKey);

  Future<void> clear() => _storage.delete(key: AppConstants.tokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);
