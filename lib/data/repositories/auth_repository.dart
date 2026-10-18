import '../../domain/models/app_user.dart';
import '../models/auth_api_model.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStore);

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

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
