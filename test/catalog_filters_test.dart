import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:pawmart/data/repositories/auth_repository.dart';
import 'package:pawmart/data/repositories/catalog_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/catalog_filters.dart';
import 'package:pawmart/ui/features/auth/view_models/auth_view_model.dart';
import 'package:pawmart/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:pawmart/ui/features/catalog/views/catalog_filter_sheet.dart';
import 'package:pawmart/ui/features/catalog/views/catalog_screen.dart';

import 'support/ui_preview.dart';

class _Tokens extends TokenStore {
  @override
  Future<String?> read() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);
  late ApiClient client;
  late AuthViewModel auth;
  late CatalogViewModel model;
  final queries = <Map<String, String>>[];
  var paged = false;
  var empty = false;
  final previewKey = GlobalKey();

  setUp(() async {
    queries.clear();
    paged = empty = false;
    final tokens = _Tokens();
    client = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: tokens,
      httpClient: MockClient((request) async {
        final Object body;
        if (request.url.path == '/api/categories') {
          body = [
            {'categoryId': 1, 'categoryName': 'Thức ăn'},
            {'categoryId': 2, 'categoryName': 'Dụng cụ'},
            {'categoryId': 3, 'categoryName': 'Đồ chơi'},
          ];
        } else {
          queries.add(Map.of(request.url.queryParameters));
          final page = int.parse(request.url.queryParameters['page'] ?? '1');
          body = {
            'page': page,
            'pageSize': 12,
            'totalItems': empty
                ? 0
                : paged
                ? 24
                : 1,
            'items': empty
                ? []
                : [
                    {
                      'productId': page,
                      'categoryId': 1,
                      'productName': 'Thức ăn Poodle',
                      'brand': 'Royal Canin',
                      'price': 250000,
                      'stockQuantity': 10,
                      'targetPetType': 'DOG',
                      'images': [],
                    },
                  ],
          };
        }
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    auth = AuthViewModel(AuthRepository(client, tokens), tokens);
    await auth.initialize();
    model = CatalogViewModel(CatalogRepository(client));
  });
  tearDown(() {
    model.dispose();
    auth.dispose();
    client.close();
  });

  Future<void> mount(
    WidgetTester tester, {
    bool open = false,
    Size size = const Size(390, 900),
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/catalog',
      routes: [
        GoRoute(
          path: '/catalog',
          builder: (_, _) => CatalogScreen(initialShowFilters: open),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: client),
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ],
        child: RepaintBoundary(
          key: previewKey,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: previewTheme,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(size: size, textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Bộ lọc'));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    final scroll = find
        .descendant(
          of: find.byType(CatalogFilterSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(target, 140, scrollable: scroll);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    final field = find.byKey(ValueKey(key));
    await reveal(tester, field);
    await tester.enterText(field, text);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }

  test(
    'All criteria reach server and survive paging, sorting and search',
    () async {
      paged = true;
      await model.load();
      await model.applyFilters(
        const CatalogFilters(
          petType: 'DOG',
          categoryId: 1,
          breed: 'Poodle',
          brand: 'Royal Canin',
          minPrice: 100000,
          maxPrice: 300000,
          inStockOnly: true,
        ),
      );
      await model.goToPage(2);
      expect(queries.last, containsPair('page', '2'));
      expect(queries.last, containsPair('pageSize', '12'));
      for (final query in queries.skip(1)) {
        expect(query, containsPair('petType', 'DOG'));
        expect(query, containsPair('categoryId', '1'));
        expect(query, containsPair('breed', 'Poodle'));
        expect(query, containsPair('brand', 'Royal Canin'));
        expect(query, containsPair('minPrice', '100000'));
        expect(query, containsPair('maxPrice', '300000'));
        expect(query, containsPair('inStock', 'true'));
      }
      expect(model.products, hasLength(1));
      expect(model.currentPage, 2);
      await model.setSort('price_asc');
      expect(model.currentPage, 1);
      await model.setSearch('adult');
      expect(queries.last, containsPair('minPrice', '100000'));
      expect(queries.last, containsPair('search', 'adult'));
      expect(queries.last, containsPair('sort', 'price_asc'));
      await model.clearFilters();
      for (final key in [
        'petType',
        'categoryId',
        'breed',
        'brand',
        'minPrice',
        'maxPrice',
        'inStock',
      ]) {
        expect(queries.last, isNot(contains(key)));
      }
      expect(queries.last, containsPair('search', 'adult'));
      expect(queries.last, containsPair('sort', 'price_asc'));
    },
  );

  test('Changing species removes a breed selection', () async {
    await model.applyFilters(
      const CatalogFilters(petType: 'DOG', breed: 'Poodle', maxPrice: 300000),
    );
    await model.setPetType('CAT');
    expect(queries.last, containsPair('petType', 'CAT'));
    expect(queries.last, isNot(contains('breed')));
    expect(queries.last, containsPair('maxPrice', '300000'));
  });

  testWidgets('Page controls request the selected page', (tester) async {
    paged = true;
    await mount(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, '2'));
    await tester.pumpAndSettle();
    expect(queries.last, containsPair('page', '2'));
    expect(queries.last, containsPair('pageSize', '12'));
    expect(find.widgetWithText(FilledButton, '2'), findsOneWidget);
    expect(find.text('Trang 2/2'), findsNothing);
  });

  testWidgets('Apply all filters once, then remove a selected criterion', (
    tester,
  ) async {
    await mount(tester, open: true);
    final before = queries.length;
    await tester.tap(find.widgetWithText(ChoiceChip, 'Chó'));
    await enter(tester, 'filter-breed', 'Poodle');
    await reveal(tester, find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thức ăn').last);
    await tester.pumpAndSettle();
    await enter(tester, 'filter-min-price', '100000');
    await enter(tester, 'filter-max-price', '300000');
    await enter(tester, 'filter-brand', 'Royal Canin');
    await reveal(tester, find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(queries, hasLength(before));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(queries, hasLength(before + 1));
    expect(queries.last, containsPair('inStock', 'true'));
    expect(queries.last, containsPair('minPrice', '100000'));
    expect(queries.last, containsPair('breed', 'Poodle'));
    expect(find.text('Bộ lọc (6)'), findsOneWidget);
    final remove = find.byTooltip('Bỏ Giống: Poodle');
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(queries.last, isNot(contains('breed')));
    expect(queries.last, containsPair('categoryId', '1'));
  });

  testWidgets('Invalid price range stays open without sending a request', (
    tester,
  ) async {
    await mount(tester, open: true);
    final before = queries.length;
    await enter(tester, 'filter-min-price', '500000');
    await enter(tester, 'filter-max-price', '100000');
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('Phải ≥ giá từ'), findsOneWidget);
    expect(find.byType(CatalogFilterSheet), findsOneWidget);
    expect(queries, hasLength(before));
    await enter(tester, 'filter-max-price', '700000');
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(queries.last, containsPair('maxPrice', '700000'));
  });

  testWidgets('Cancel discards drafts; reset only applies after confirming', (
    tester,
  ) async {
    await mount(tester, open: true);
    final before = queries.length;
    await enter(tester, 'filter-breed', 'Poodle');
    await tester.tap(find.byTooltip('Đóng bộ lọc'));
    await tester.pumpAndSettle();
    expect(queries, hasLength(before));
    await openSheet(tester);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('filter-breed')))
          .controller!
          .text,
      isEmpty,
    );
    await enter(tester, 'filter-max-price', '100000');
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bộ lọc (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt lại'));
    await tester.pumpAndSettle();
    final requestsBeforeApply = queries.length;
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(queries, hasLength(requestsBeforeApply + 1));
    expect(queries.last, isNot(contains('maxPrice')));
  });

  for (final size in [
    const Size(360, 800),
    const Size(740, 400),
    const Size(1000, 900),
  ]) {
    testWidgets('Filter panel fits $size with larger text', (tester) async {
      await mount(tester, open: true, size: size, scale: 1.3);
      expect(tester.takeException(), isNull);
      await reveal(tester, find.byType(SwitchListTile));
      expect(tester.takeException(), isNull);
      expect(find.text('Áp dụng bộ lọc'), findsOneWidget);
    });
  }

  testWidgets('Filter footer stays usable with a landscape keyboard', (
    tester,
  ) async {
    await mount(tester, open: true, size: const Size(740, 400), scale: 1.3);
    addTearDown(tester.view.resetViewInsets);
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    expect(find.text('Áp dụng bộ lọc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filter visual preview', (tester) async {
    await mount(tester, open: true);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Chó'));
    await enter(tester, 'filter-breed', 'Poodle');
    await tester.drag(
      find.descendant(
        of: find.byType(CatalogFilterSheet),
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    await capturePreview(tester, previewKey, 'catalog-filter-sheet');
    await reveal(tester, find.widgetWithText(ChoiceChip, '100.000–300.000đ'));
    await tester.tap(find.widgetWithText(ChoiceChip, '100.000–300.000đ'));
    await tester.pumpAndSettle();
    await capturePreview(tester, previewKey, 'catalog-filter-price');
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    await capturePreview(tester, previewKey, 'catalog-filter-results');
    expect(tester.takeException(), isNull);
  });
}
