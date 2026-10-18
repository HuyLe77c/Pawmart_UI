import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/token_store.dart';
import '../../../../domain/models/app_user.dart';

enum AuthStatus { initializing, signedOut, signedIn }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository, this._tokenStore);

  final AuthRepository _repository;
  final TokenStore _tokenStore;

  AuthStatus _status = AuthStatus.initializing;
  AppUser? _user;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;

  Future<void> initialize() async {
    try {
      final token = await _tokenStore.read();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.signedOut;
      } else {
        _user = await _repository.me();
        _status = AuthStatus.signedIn;
      }
    } on ApiException {
      await _tokenStore.clear();
      _user = null;
      _status = AuthStatus.signedOut;
    } catch (_) {
      await _tokenStore.clear();
      _user = null;
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) =>
      _submit(() => _repository.login(email: email, password: password));

  Future<bool> register({
    required String email,
    required String fullName,
    required String password,
    String? phoneNumber,
  }) => _submit(
    () => _repository.register(
      email: email,
      fullName: fullName,
      password: password,
      phoneNumber: phoneNumber,
    ),
  );

  Future<bool> _submit(Future<AppUserSession> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final session = await action();
      _user = session.user;
      _status = AuthStatus.signedIn;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.userMessage;
      return false;
    } catch (_) {
      _errorMessage = 'Không thể đăng nhập lúc này. Vui lòng thử lại.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _status = AuthStatus.signedOut;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> handleSessionExpired() async {
    await _tokenStore.clear();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
