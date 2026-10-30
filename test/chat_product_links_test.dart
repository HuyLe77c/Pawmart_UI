import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pawmart/domain/models/chat_reply.dart';
import 'package:pawmart/ui/features/chat_ai/views/chat_product_links.dart';

void main() {
  testWidgets('Chạm sản phẩm trong câu trả lời mở đúng trang chi tiết', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: ChatProductLinks(
              products: [
                ChatProductLink(
                  productId: 5,
                  productName: 'Hạt mèo trưởng thành vị cá hồi',
                  price: 120000,
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Chi tiết ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Hạt mèo trưởng thành vị cá hồi'), findsOneWidget);
    await tester.tap(find.text('Hạt mèo trưởng thành vị cá hồi'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết 5'), findsOneWidget);
  });
}
