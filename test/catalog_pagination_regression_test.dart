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
import 'package:pawmart/ui/features/catalog/views/catalog_screen.dart';

class _Tokens extends TokenStore {
  @override
  Future<String?> read() async => null;
}

void main() {
  for (final shrinks in [false, true]) {
    testWidgets(
      shrinks
          ? 'Catalog recovers when the requested page no longer exists'
          : 'Catalog starts the next page at the top after loading',
      (tester) async {
        var catalogShrunk = false;
        final tokens = _Tokens();
        final client = ApiClient(
          baseUrl: 'http://localhost',
          tokenStore: tokens,
          httpClient: MockClient((request) async {
            if (request.url.path == '/api/categories') {
              return http.Response('[]', 200);
            }
            final page = int.parse(request.url.queryParameters['page'] ?? '1');
            await Future<void>.delayed(const Duration(milliseconds: 80));
            if (shrinks && page == 2) catalogShrunk = true;
            final items = catalogShrunk && page == 2
                ? []
                : [
                    for (var id = 1; id <= 12; id++)
                      {
                        'productId': id + (page - 1) * 12,
                        'categoryId': 1,
                        'productName': 'Product $page-$id',
                        'price': 100000,
                        'stockQuantity': 20,
                        'images': [],
                      },
                  ];
            return http.Response(
              jsonEncode({
                'items': items,
                'page': page,
                'pageSize': 12,
                'totalItems': catalogShrunk ? 12 : 24,
              }),
              200,
            );
          }),
        );
        final auth = AuthViewModel(AuthRepository(client, tokens), tokens);
        await auth.initialize();
        final router = GoRouter(
          initialLocation: '/catalog',
          routes: [
            GoRoute(path: '/catalog', builder: (_, _) => const CatalogScreen()),
          ],
        );
        addTearDown(() {
          router.dispose();
          auth.dispose();
          client.close();
        });
        await tester.binding.setSurfaceSize(const Size(390, 850));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<ApiClient>.value(value: client),
              ChangeNotifierProvider<AuthViewModel>.value(value: auth),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        final next = find.widgetWithText(OutlinedButton, '2');
        await tester.scrollUntilVisible(
          next,
          350,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
        if (shrinks) {
          expect(find.text('Chưa có sản phẩm phù hợp'), findsNothing);
          expect(find.text('Product 1-1'), findsOneWidget);
          expect(find.widgetWithText(OutlinedButton, '2'), findsNothing);
        } else {
          final list = tester.widget<CustomScrollView>(
            find.byType(CustomScrollView),
          );
          expect(
            list.controller!.offset,
            0,
            reason:
                'A new page should not restore the previous page bottom offset',
          );
        }
      },
    );
  }
}
