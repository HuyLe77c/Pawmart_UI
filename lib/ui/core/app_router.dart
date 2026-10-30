import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/views/cart_screen.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/sign_in_screen.dart';
import '../features/assistant/views/assistant_screen.dart';
import '../features/chat_ai/views/chat_ai_screen.dart';
import '../features/checkout/views/checkout_screen.dart';
import '../features/catalog/views/catalog_screen.dart';
import '../features/customer/views/customer_shell.dart';
import '../features/home/views/home_screen.dart';
import '../features/pets/views/pet_profiles_screen.dart';
import '../features/product_detail/views/product_detail_screen.dart';
import '../features/orders/views/orders_screen.dart';
import '../features/orders/views/order_detail_screen.dart';
import '../features/admin/views/admin_shell.dart';
import '../features/admin/views/admin_screens.dart';
import '../features/notifications/views/notifications_screen.dart';

GoRouter createAppRouter(AuthViewModel auth) => GoRouter(
  initialLocation: '/',
  refreshListenable: auth,
  redirect: (context, state) {
    final path = state.uri.path;
    final isAuthPage = path == '/sign-in' || path == '/register';
    final isPublicPage = path == '/catalog' || path.startsWith('/products/');

    if (auth.status == AuthStatus.initializing) return null;
    if (!auth.isSignedIn) {
      if (path == '/') return '/catalog';
      if (isAuthPage || isPublicPage) return null;
      return '/sign-in?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }

    final home = auth.user!.isAdmin ? '/admin/overview' : '/customer/home';
    if (path == '/') return home;
    if (isAuthPage) {
      final requested = state.uri.queryParameters['redirect'];
      if (requested != null) {
        final target = Uri.tryParse(requested);
        final path = target?.path ?? '';
        final isInternal =
            target != null && !target.hasScheme && target.hasAuthority == false;
        final roleMatches = auth.user!.isAdmin
            ? path.startsWith('/admin/')
            : path.startsWith('/customer/') ||
                  path == '/catalog' ||
                  path.startsWith('/products/');
        if (isInternal && roleMatches) return target.toString();
      }
      return home;
    }
    if (auth.user!.isAdmin && path.startsWith('/customer')) return home;
    if (!auth.user!.isAdmin && path.startsWith('/admin')) return home;
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const _LoadingPage()),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/catalog',
      builder: (context, state) => CatalogScreen(
        initialSearch: state.uri.queryParameters['search'],
        initialCategoryId: int.tryParse(
          state.uri.queryParameters['categoryId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/products/:id',
      builder: (context, state) => ProductDetailScreen(
        productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
      ),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          CustomerShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/customer/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/customer/categories',
          builder: (context, state) => CatalogScreen(
            initialSearch: state.uri.queryParameters['search'],
            initialCategoryId: int.tryParse(
              state.uri.queryParameters['categoryId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/customer/assistant',
          builder: (context, state) => const AssistantScreen(),
        ),
        GoRoute(
          path: '/customer/chat-ai',
          builder: (context, state) => const ChatAiScreen(),
        ),
        GoRoute(
          path: '/customer/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/customer/orders/:orderId',
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['orderId']!),
        ),
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const PetProfilesScreen(),
        ),
        GoRoute(
          path: '/customer/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/customer/checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AdminShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/admin/overview',
          builder: (context, state) => const AdminOverviewScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => const AdminProductsScreen(),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const AdminOrdersScreen(),
        ),
        GoRoute(
          path: '/admin/more',
          builder: (context, state) => const AdminMoreScreen(),
        ),
      ],
    ),
  ],
);

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
