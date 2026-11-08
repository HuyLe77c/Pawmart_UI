import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/app_user.dart';
import '../models/auth_api_model.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStore);

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '748019020479-13pno6ssmt4dn4a7s7quvkgr029oma45.apps.googleusercontent.com',
  );
  static Future<void>? _googleInitialization;

  Future<AppUserSession> loginWithGoogle() async {
    if (_googleWebClientId.isEmpty) {
      throw StateError(
        'Đăng nhập Google chưa được cấu hình cho bản ứng dụng này.',
      );
    }
    final google = GoogleSignIn.instance;
    try {
      _googleInitialization ??= google.initialize(
        serverClientId: _googleWebClientId,
      );
      await _googleInitialization;
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
    await google.signOut();
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google không cung cấp mã xác thực. Vui lòng thử lại.');
    }
    final json = await _apiClient.postJson('api/auth/google', {
      'idToken': idToken,
    }) as Map<String, dynamic>;
    final session = AuthApiModel.fromJson(json).toDomain();
    await _tokenStore.write(session.accessToken);
    return session;
  }

  Future<AppUserSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _apiClient.postJson('api/auth/login', {
      'email': email.trim(),
      'password': password,
    }) as Map<String, dynamic>;
    final session = AuthApiModel.fromJson(json).toDomain();
    await _tokenStore.write(session.accessToken);
    return session;
  }

  Future<AppUserSession> register({
    required String email,
    required String fullName,
    required String password,
    String? phoneNumber,
  }) async {
    final json = await _apiClient.postJson('api/auth/register', {
      'email': email.trim(),
      'fullName': fullName.trim(),
      'password': password,
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        'phoneNumber': phoneNumber.trim(),
    }) as Map<String, dynamic>;
    final session = AuthApiModel.fromJson(json).toDomain();
    await _tokenStore.write(session.accessToken);
    return session;
  }

  Future<AppUser> me() async {
    final json =
        await _apiClient.getJson('api/auth/me') as Map<String, dynamic>;
    return UserApiModel.fromJson(json).toDomain();
  }

  Future<void> signOut() => _tokenStore.clear();
}
