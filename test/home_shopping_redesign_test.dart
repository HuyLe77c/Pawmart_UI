import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/ui/core/app_theme.dart';
import 'package:pawmart/ui/features/customer/views/customer_shell.dart';
import 'package:pawmart/ui/features/home/views/home_screen.dart';
import 'package:pawmart/ui/core/widgets/product_card.dart';

class _Tokens extends TokenStore {
  @override
  Future<String?> read() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final configFile = File('.dart_tool/package_config.json').absolute;
    final packages =
        jsonDecode(await configFile.readAsString())['packages'] as List;
    final package = packages.firstWhere((item) => item['name'] == 'flutter');
    final fonts = Directory.fromUri(
      configFile.uri.resolve(package['rootUri'] as String),
    ).uri.resolve('../../bin/cache/artifacts/material_fonts/');
    for (final family in ['Roboto', 'Ahem']) {
      await (FontLoader(family)..addFont(
            File.fromUri(fonts.resolve('roboto-regular.ttf'))
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
    await (FontLoader('MaterialIcons')..addFont(
          File.fromUri(fonts.resolve('MaterialIcons-Regular.otf'))
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });

  late ApiClient client;
  late GoRouter router;
  final requests = <http.Request>[];
  var empty = false;
  var loadFails = false;
  var addFails = false;
  var preview = false;
  String? copied;
  final boundaryKey = GlobalKey();

  setUp(() {
    empty = loadFails = addFails = preview = false;
    copied = null;
    requests.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    client = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: _Tokens(),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        final Object body;
        var status = 200;
        if (loadFails && path == '/api/categories') {
          status = 503;
          body = {
            'title': 'Unavailable',
            'detail': 'Cửa hàng tạm thời không khả dụng.',
          };
        } else if (path == '/api/categories') {
          body = [
            for (final item in [
              (1, 'Cat Food'),
              (2, 'Dog Food'),
              (3, 'Treats'),
              (4, 'Accessories'),
            ])
              {'categoryId': item.$1, 'categoryName': item.$2},
          ];
        } else if (path == '/api/products') {
          body = {
            'items': empty
                ? []
                : [
                    for (final item in [
                      (1, 'Hạt mèo trưởng thành vị cá hồi', 'CAT', 189000),
                      (2, 'Thức ăn cho chó trưởng thành', 'DOG', 215000),
                      (3, 'Bánh thưởng cho mèo', 'CAT', 65000),
                      (4, 'Bát ăn cho cún', 'DOG', 85000),
                    ])
                      {
                        'productId': item.$1,
                        'categoryId': item.$1,
                        'productName': item.$2,
                        'targetPetType': item.$3,
                        'price': preview ? 0 : item.$4,
                        'stockQuantity': preview ? 0 : 20,
                        'isFeatured': item.$1 <= 2,
                        'isActive': !preview,
                        'brand': 'PawMart',
                        'images': [],
                        if (preview)
                          'catalogReview': {
                            'publicPreview': true,
                            'imageStatus': 'NEEDS_REVIEW',
                            'priceStatus': 'NEEDS_REVIEW',
                          },
                      },
                  ],
          };
        } else if (path == '/api/promotions') {
          body = [
            {
              'promotionId': 1,
              'promotionName': 'Ưu đãi cho đơn hàng của bé',
              'code': 'PAW10',
              'discountType': 'PERCENT',
              'discountValue': 10,
              'startAt': '2026-11-01T00:00:00Z',
              'endAt': '2026-12-01T00:00:00Z',
              'minOrderAmount': 200000,
            },
          ];
        } else if (path == '/api/reviews') {
          body = {'items': [], 'total': 0, 'averageRating': 0};
        } else if (path == '/api/cart/items' && addFails) {
          status = 409;
          body = {'title': 'Conflict', 'detail': 'Sản phẩm vừa hết hàng.'};
        } else if (path == '/api/cart') {
          body = {
            'items': [
              {
                'productId': 1,
                'productName': 'Hạt mèo',
                'unitPrice': 189000,
                'quantity': 2,
                'lineTotal': 378000,
                'availableStock': 20,
              },
            ],
            'totalQuantity': 2,
          };
        } else {
          body = {'items': [], 'totalQuantity': 3};
        }
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    router = GoRouter(
      initialLocation: '/customer/home',
      routes: [
        GoRoute(
          path: '/customer/home',
          builder: (_, _) =>
              const CustomerShell(path: '/customer/home', child: HomeScreen()),
        ),
        for (final path in [
          '/customer/categories',
          '/customer/cart',
          '/customer/chat-ai',
          '/customer/notifications',
          '/stores',
          '/products/:id',
        ])
          GoRoute(
            path: path,
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
      ],
    );
  });
  tearDown(() {
    router.dispose();
    client.close();
  });

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 900),
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final theme = PawmartTheme.light;
    await tester.pumpWidget(
      Provider<ApiClient>.value(
        value: client,
        child: RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
              filledButtonTheme: FilledButtonThemeData(
                style: theme.filledButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontFamily: 'Roboto'),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: theme.textButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontFamily: 'Roboto'),
                  ),
                ),
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> snapshot(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/ui-previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final size in [
    const Size(360, 800),
    const Size(740, 400),
    const Size(1100, 900),
  ]) {
    testWidgets('Shopping overview adapts to $size with larger text', (
      tester,
    ) async {
      await mount(tester, size: size, scale: 1.3);
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text('Sản phẩm nổi bật'));
      await reveal(tester, find.text('Ưu đãi dành cho bạn'));
      await reveal(tester, find.text('Khám phá thêm'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Search passes the typed query to the catalog', (tester) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'cá hồi & pate');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['search'],
      'cá hồi & pate',
    );
    expect(
      router.routeInformationProvider.value.uri.path,
      '/customer/categories',
    );
  });
  for (final entry in [('Mua cho cún', 'DOG'), ('Mua cho mèo', 'CAT')]) {
    testWidgets('${entry.$1} filters the catalog', (tester) async {
      await mount(tester);
      await reveal(tester, find.text(entry.$1));
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters['petType'],
        entry.$2,
      );
    });
  }
  testWidgets('Home filter action opens the catalog with the current search', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'poodle');
    await tester.tap(find.byTooltip('Lọc sản phẩm'));
    await tester.pumpAndSettle();
    expect(
      find.text('/customer/categories?filters=1&search=poodle'),
      findsOneWidget,
    );
  });

  testWidgets('Category opens its catalog filter', (tester) async {
    await mount(tester);
    await reveal(tester, find.text('Thức ăn cho mèo'));
    await tester.tap(find.text('Thức ăn cho mèo'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['categoryId'],
      '1',
    );
  });
  testWidgets('Adding a product preserves its existing cart quantity', (
    tester,
  ) async {
    await mount(tester);
    await reveal(tester, find.byKey(const ValueKey('home-product-1')));
    final add = find.descendant(
      of: find.byType(ProductCard).first,
      matching: find.byTooltip('Thêm vào giỏ'),
    );
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    final put = requests.singleWhere((request) => request.method == 'PUT');
    expect(jsonDecode(put.body), {'productId': 1, 'quantity': 3});
    expect(find.text('Đã thêm vào giỏ hàng.'), findsOneWidget);
    await tester.tap(find.text('Xem giỏ'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/customer/cart');
  });
  testWidgets('Cart errors stay visible without success feedback', (
    tester,
  ) async {
    addFails = true;
    await mount(tester);
    await reveal(tester, find.byKey(const ValueKey('home-product-1')));
    final add = find.descendant(
      of: find.byType(ProductCard).first,
      matching: find.byTooltip('Thêm vào giỏ'),
    );
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Sản phẩm vừa hết hàng.'), findsOneWidget);
    expect(find.text('Đã thêm vào giỏ hàng.'), findsNothing);
  });
  testWidgets('Coupon copy uses the actual promotion code', (tester) async {
    await mount(tester);
    await reveal(tester, find.text('Sao chép mã'));
    await tester.tap(find.text('Sao chép mã'));
    await tester.pumpAndSettle();
    expect(copied, 'PAW10');
  });
  testWidgets('Preview products remain unavailable to purchase', (
    tester,
  ) async {
    preview = true;
    await mount(tester);
    await reveal(tester, find.byKey(const ValueKey('home-product-1')));
    expect(find.byTooltip('Thêm vào giỏ'), findsNothing);
    expect(find.text('Sắp mở bán'), findsWidgets);
  });
  testWidgets('Empty catalog provides a useful next step', (tester) async {
    empty = true;
    await mount(tester);
    await reveal(tester, find.text('Cửa hàng đang cập nhật'));
    expect(find.text('Hỏi PawMart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Failed load can be retried', (tester) async {
    loadFails = true;
    await mount(tester);
    expect(find.text('Cửa hàng tạm thời không khả dụng.'), findsOneWidget);
    loadFails = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
  testWidgets('Shopping overview visual previews', (tester) async {
    await mount(tester);
    await snapshot(tester, 'shopping-home');
    await reveal(tester, find.text('Sản phẩm nổi bật'));
    await snapshot(tester, 'shopping-products');
    expect(tester.takeException(), isNull);
  });
}
