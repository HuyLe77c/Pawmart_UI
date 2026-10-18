import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/cart_repository.dart';
import '../../data/services/api_client.dart';
import '../features/auth/view_models/auth_view_model.dart';

Future<bool> addProductToCart(
  BuildContext context, {
  required int productId,
  int quantity = 1,
}) async {
  if (!context.read<AuthViewModel>().isSignedIn) {
    context.go('/sign-in?redirect=/customer/cart');
    return false;
  }
  try {
    final repository = CartRepository(context.read<ApiClient>());
    final cart = await repository.getCart();
    final current = cart.items
        .where((line) => line.productId == productId)
        .firstOrNull;
    await repository.setQuantity(
      productId: productId,
      quantity: (current?.quantity ?? 0) + quantity,
    );
    return true;
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật giỏ hàng. Hãy thử lại.'),
        ),
      );
    }
  }
  return false;
}
