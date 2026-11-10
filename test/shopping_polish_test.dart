import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:pawmart/data/repositories/auth_repository.dart';
import 'package:pawmart/data/repositories/chat_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/pet_profile.dart';
import 'package:pawmart/ui/core/widgets/shopping_action_bar.dart';
import 'package:pawmart/ui/features/auth/view_models/auth_view_model.dart';
import 'package:pawmart/ui/features/cart/views/cart_screen.dart';
import 'package:pawmart/ui/features/chat_ai/view_models/chat_ai_view_model.dart';
import 'package:pawmart/ui/features/chat_ai/views/chat_ai_screen.dart';
import 'package:pawmart/ui/features/checkout/views/checkout_screen.dart';
import 'package:pawmart/ui/features/product_detail/views/product_detail_screen.dart';

import 'support/ui_preview.dart';

class _Tokens extends TokenStore {
  @override
  Future<String?> read() async => null;
}

class _PreviewImageClient extends Fake implements HttpClient {
  _PreviewImageClient(this.bytes);
  final List<int> bytes;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _PreviewImageRequest(bytes);
}

class _PreviewImageRequest extends Fake implements HttpClientRequest {
  _PreviewImageRequest(this.bytes);
  final List<int> bytes;

  @override
  Future<HttpClientResponse> close() async => _PreviewImageResponse(bytes);
}

class _PreviewImageResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _PreviewImageResponse(this.bytes);
  final List<int> bytes;

  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);
  late ApiClient api;
  late AuthViewModel auth;
  late ChatAiViewModel chat;
  late List<http.Request> requests;
  final preview = GlobalKey();
  var previewOnly = false;
  const photoPath = String.fromEnvironment('PREVIEW_PRODUCT_PHOTO');

  setUp(() {
    requests = [];
    previewOnly = false;
    final tokens = _Tokens();
    api = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: tokens,
      httpClient: MockClient((request) async {
        requests.add(request);
        final line = {
          'productId': 1,
          'productName': 'Hạt cá hồi cho mèo trưởng thành',
          'quantity': 2,
          'unitPrice': 149000,
          'lineTotal': 298000,
          'availableStock': 8,
        };
        final Object result = switch (request.url.path) {
          '/api/products/1' => {
            'productId': 1,
            'categoryId': 1,
            'productName': photoPath.isNotEmpty
                ? 'Royal Canin Maxi Adult'
                : 'Hạt cá hồi cho mèo trưởng thành',
            'stockQuantity': previewOnly ? 0 : 8,
            'price': previewOnly ? 0 : 149000,
            'isActive': !previewOnly,
            'targetPetType': photoPath.isNotEmpty ? 'DOG' : 'CAT',
            'brand': photoPath.isNotEmpty ? 'Royal Canin' : 'PawMart',
            'description': photoPath.isNotEmpty
                ? 'Thức ăn khô dành cho chó trưởng thành giống lớn, trên 15 tháng tuổi.'
                : 'Thức ăn hạt vị cá hồi dành cho mèo trưởng thành. Hạt nhỏ, dễ chia thành nhiều bữa trong ngày.',
            if (photoPath.isEmpty) 'packageSize': '1,5 kg',
            'lifeStage': 'Trưởng thành',
            if (photoPath.isEmpty) 'sku': 'PM-CAT-015',
            if (photoPath.isEmpty)
              'ingredients': 'Cá hồi, gạo, dầu cá và chất xơ.',
            if (photoPath.isEmpty)
              'nutritionInfo': 'Đạm thô 30%; chất béo thô 14%.',
            'feedingGuide': 'Chia khẩu phần theo hướng dẫn trên bao bì. Luôn chuẩn bị nước sạch cho bé.',
            if (previewOnly) 'catalogReview': {'publicPreview': true},
            'images': [
              {'imageUrl': '/example-front.jpg', 'isPrimary': true},
              if (photoPath.isEmpty)
                {'imageUrl': '/example-back.jpg', 'displayOrder': 1},
            ],
          },
          '/api/cart' => {
            'items': [line],
            'subtotal': 298000,
            'totalQuantity': 2,
          },
          '/api/cart/checkout/quote' => {
            'items': [line],
            'subtotal': 298000,
            'discount': 0,
            'shippingFee': 25000,
            'total': 323000,
            'fingerprint': 'demo',
          },
          '/api/cart/checkout/payment-methods' => {'bankQrAvailable': true},
          '/api/chat/messages' => {
            'answer': 'Miu nên ăn thức ăn phù hợp với tuổi.',
            'products': [],
          },
          _ => {},
        };
        return http.Response(
          jsonEncode(result),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    auth = AuthViewModel(AuthRepository(api, tokens), tokens);
    chat = ChatAiViewModel(ChatRepository(api), auth);
    addTearDown(() {
      chat.dispose();
      auth.dispose();
      api.close();
    });
  });

  Future<void> show(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ],
        child: RepaintBoundary(
          key: preview,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: previewTheme,
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Gallery thumbnails select a photo and open its large view', (
    tester,
  ) async {
    await show(tester, const ProductDetailScreen(productId: 1));
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ảnh sản phẩm 2'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Xem ảnh lớn'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng ảnh'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Product details link scrolls to facts and usage guide', (
    tester,
  ) async {
    if (photoPath.isNotEmpty) {
      final bytes = File(photoPath).readAsBytesSync();
      debugNetworkImageHttpClientProvider = () => _PreviewImageClient(bytes);
    }
    try {
      if (photoPath.isNotEmpty) {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final artworkContext = tester.element(find.byType(SizedBox).last);
        await tester.runAsync(
          () => precacheImage(
            const NetworkImage('http://localhost/example-front.jpg'),
            artworkContext,
          ),
        );
      }
      await show(tester, const ProductDetailScreen(productId: 1));
      await capturePreview(tester, preview, 'product-detail-hero');
      final details = find.text('Xem thông tin chi tiết');
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.text('Thông tin sản phẩm').hitTestable(), findsOneWidget);
      if (photoPath.isEmpty) {
        expect(find.text('Thành phần'), findsOneWidget);
        expect(find.text('Thông tin dinh dưỡng'), findsOneWidget);
      }
      expect(find.text('Hướng dẫn sử dụng'), findsOneWidget);
      await capturePreview(tester, preview, 'product-detail-information');
      expect(tester.takeException(), isNull);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });

  testWidgets(
    'Unpublished product hides purchase controls and shows its status',
    (tester) async {
      previewOnly = true;
      await show(
        tester,
        const ProductDetailScreen(productId: 1),
        size: const Size(1040, 780),
      );
      expect(find.text('Sắp mở bán'), findsOneWidget);
      expect(find.text('Giá chưa công bố'), findsOneWidget);
      expect(find.text('Thêm vào giỏ'), findsNothing);
      expect(find.byTooltip('Tăng số lượng'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cart keeps subtotal and checkout action visible', (
    tester,
  ) async {
    await show(tester, const CartScreen());
    expect(find.text('2 món dành cho bé'), findsOneWidget);
    expect(find.text('Tiếp tục thanh toán'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturePreview(tester, preview, 'shopping-cart-polished');
  });

  testWidgets(
    'Fixed checkout button validates delivery fields before placing an order',
    (tester) async {
      await show(tester, const CheckoutScreen());
      expect(
        find.descendant(
          of: find.byType(ShoppingActionBar),
          matching: find.text('Tổng thanh toán'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('323.000'), findsWidgets);
      await capturePreview(tester, preview, 'checkout-polished');
      await tester.tap(find.text('Đặt hàng'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập họ tên hợp lệ'), findsOneWidget);
      expect(
        requests.any((request) => request.url.path == '/api/cart/checkout'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Chat displays the selected pet and sends its name as context', (
    tester,
  ) async {
    await show(
      tester,
      ChatAiScreen(
        viewModel: chat,
        pet: const PetProfile(petId: 1, petName: 'Miu', petType: 'CAT'),
      ),
    );
    expect(find.text('Đang hỏi về Miu'), findsOneWidget);
    await capturePreview(tester, preview, 'pet-chat-polished');
    await tester.enterText(find.byType(TextField), 'Bé nên ăn gì?');
    await tester.pump();
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pumpAndSettle();
    final request = requests.singleWhere(
      (request) => request.url.path == '/api/chat/messages',
    );
    expect(
      jsonDecode(request.body)['message'],
      contains('Hồ sơ thú cưng đang chọn: Miu.'),
    );
    expect(find.text('Bé nên ăn gì?'), findsOneWidget);
  });
}
