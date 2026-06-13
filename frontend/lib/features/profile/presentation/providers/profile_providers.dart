import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileActionState {
  final bool isSaving;
  final bool isUploadingCv;
  final bool isUploadingAvatar;
  final String? error;
  const ProfileActionState({
    this.isSaving = false,
    this.isUploadingCv = false,
    this.isUploadingAvatar = false,
    this.error,
  });

  ProfileActionState copyWith({
    bool? isSaving,
    bool? isUploadingCv,
    bool? isUploadingAvatar,
    String? error,
    bool clearError = false,
  }) {
    return ProfileActionState(
      isSaving: isSaving ?? this.isSaving,
      isUploadingCv: isUploadingCv ?? this.isUploadingCv,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileNotifier extends Notifier<ProfileActionState> {
  late final ProfileRepository _repo;

  @override
  ProfileActionState build() {
    _repo = ref.read(profileRepositoryProvider);
    return const ProfileActionState();
  }

  /// Met à jour le profil étudiant puis recharge la session. Renvoie null si OK.
  Future<String?> updateStudent(Map<String, dynamic> body) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.updateStudent(body);
      await ref.read(authProvider.notifier).restoreSession();
      state = state.copyWith(isSaving: false);
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> updateCompany(Map<String, dynamic> body) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.updateCompany(body);
      await ref.read(authProvider.notifier).restoreSession();
      state = state.copyWith(isSaving: false);
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> uploadAvatar({required String filePath, required String fileName, required bool isCompany}) async {
    state = state.copyWith(isUploadingAvatar: true, clearError: true);
    try {
      await _repo.uploadAvatar(filePath: filePath, fileName: fileName, isCompany: isCompany);
      await ref.read(authProvider.notifier).restoreSession();
      state = state.copyWith(isUploadingAvatar: false);
      return null;
    } catch (e) {
      state = state.copyWith(isUploadingAvatar: false, error: e.toString());
      return e.toString();
    }
  }

  /// Upload du CV. Renvoie null si OK, sinon message d'erreur.
  Future<String?> uploadCv({required String filePath, required String fileName}) async {
    state = state.copyWith(isUploadingCv: true, clearError: true);
    try {
      await _repo.uploadCv(filePath: filePath, fileName: fileName);
      await ref.read(authProvider.notifier).restoreSession();
      state = state.copyWith(isUploadingCv: false);
      return null;
    } catch (e) {
      state = state.copyWith(isUploadingCv: false, error: e.toString());
      return e.toString();
    }
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileActionState>(ProfileNotifier.new);
