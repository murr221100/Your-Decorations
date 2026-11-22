import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../features/admin/admin_screen.dart';
import '../features/admin/product_form_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/cart/checkout_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/products/home_screen.dart';
import '../features/products/product_details_screen.dart';
import 'providers.dart';

String loginPath(String from) =>
    Uri(path: '/login', queryParameters: {'from': from}).toString();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isLoading) return null;
      final loggedIn = auth.value != null;
      final path = state.uri.path;

      if (path == '/login') {
        return loggedIn ? (state.uri.queryParameters['from'] ?? '/') : null;
      }
      const protectedPrefixes = ['/checkout', '/orders', '/admin'];
      final needsLogin = protectedPrefixes.any((p) => path.startsWith(p));
      if (needsLogin && !loggedIn) return loginPath(state.uri.toString());
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (_, s) => ProductDetailsScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      GoRoute(
        path: '/admin/product',
        builder: (_, s) => ProductFormScreen(product: s.extra as Product?),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
