import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawmart/domain/models/product.dart';
import 'package:pawmart/ui/core/app_theme.dart';
import 'package:pawmart/ui/core/widgets/product_card.dart';

void main() {
  testWidgets('Thẻ sản phẩm không tràn ở ô lưới nhỏ', (tester) async {
    const product = Product(
      productId: 1,
      categoryId: 1,
      productName: 'Thức ăn cho mèo trưởng thành vị cá hồi và rau củ',
      price: 279000,
      stockQuantity: 12,
      lowStockThreshold: 5,
      targetPetType: 'CAT',
      isFeatured: true,
      isActive: true,
      images: [],
      brand: 'PawMart Nutrition',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PawmartTheme.light,
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: SizedBox(
                width: 148,
                height: 258,
                child: ProductCard(
                  product: product,
                  onTap: () {},
                  onAdd: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('279.000'), findsOneWidget);
  });
}
