import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:pawmart/data/repositories/auth_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/ui/features/auth/view_models/auth_view_model.dart';
import 'package:pawmart/ui/features/auth/views/register_screen.dart';

class _MemoryTokenStore extends TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;
}

void main() {
  late _MemoryTokenStore tokens;
  late AuthViewModel auth;
  var failRegistration = false;

  setUp(() async {
    failRegistration = false;
    tokens = _MemoryTokenStore();
    final client = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: tokens,
      httpClient: MockClient((request) async {
        if (failRegistration) {
          return http.Response(
            jsonEncode({'title': 'Conflict', 'detail': 'Email already registered.'}),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'accessToken': 'test-token',
            'expiresAtUtc': '2030-01-01T00:00:00Z',
            'user': {
              'userId': 'customer-1',
              'email': 'customer@example.com',
              'fullName': 'Customer',
              'role': 'CUSTOMER',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    auth = AuthViewModel(AuthRepository(client, tokens), tokens);
    await auth.initialize();
    addTearDown(auth.dispose);
  });

  test('Registration does not save a token or sign the customer in', () async {
    expect(await auth.register(
      email: 'customer@example.com', fullName: 'Customer', password: 'password123',
    ), isTrue);
    expect(tokens.token, isNull);
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.user, isNull);
  });

  test('Explicit sign in still saves the session', () async {
    expect(await auth.signIn('customer@example.com', 'password123'), isTrue);
    expect(tokens.token, 'test-token');
    expect(auth.isSignedIn, isTrue);
  });

  for (final fails in [false, true]) {
    testWidgets('Registration ${fails ? 'failure stays on form' : 'success opens sign in'}', (tester) async {
      failRegistration = fails;
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
          GoRoute(path: '/sign-in', builder: (_, _) => const Scaffold(body: Text('Sign in destination'))),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Customer');
      await tester.enterText(fields.at(1), 'customer@example.com');
      await tester.enterText(fields.at(3), 'password123');
      final submit = find.widgetWithText(FilledButton, 'Tạo tài khoản');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(tokens.token, isNull);
      expect(auth.isSignedIn, isFalse);
      expect(router.routeInformationProvider.value.uri.path, fails ? '/register' : '/sign-in');
      if (!fails) {
        expect(find.text('Đăng ký thành công. Vui lòng đăng nhập để tiếp tục.'), findsOneWidget);
      }
    });
  }
}
