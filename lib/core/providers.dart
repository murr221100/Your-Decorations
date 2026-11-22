import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/repositories.dart';

final authRepoProvider = Provider((ref) => AuthRepository());
final productRepoProvider = Provider((ref) => ProductRepository());
final orderRepoProvider = Provider((ref) => OrderRepository());
final inquiryRepoProvider = Provider((ref) => InquiryRepository());

final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authRepoProvider).authStateChanges);

final isAdminProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);
  return ref.watch(authRepoProvider).watchIsAdmin(user.id);
});

final productsProvider = StreamProvider<List<Product>>(
    (ref) => ref.watch(productRepoProvider).watchAll());

final productProvider = StreamProvider.family<Product?, String>(
    (ref, id) => ref.watch(productRepoProvider).watchOne(id));

final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <OrderModel>[]);
  return ref.watch(orderRepoProvider).watchMine(user.id);
});

final allOrdersProvider = StreamProvider<List<OrderModel>>(
    (ref) => ref.watch(orderRepoProvider).watchAll());

final inquiriesProvider = StreamProvider<List<Inquiry>>(
    (ref) => ref.watch(inquiryRepoProvider).watchAll());

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void add(Product p) {
    final i = state.indexWhere((e) => e.productId == p.id);
    if (i == -1) {
      state = [
        ...state,
        CartItem(
          productId: p.id,
          name: p.name,
          price: p.price,
          image: p.images.isEmpty ? null : p.images.first,
          qty: 1,
          maxStock: p.stock,
        ),
      ];
    } else if (state[i].qty < state[i].maxStock) {
      final list = [...state];
      list[i] = list[i].copyWith(qty: list[i].qty + 1);
      state = list;
    }
  }

  void setQty(String id, int qty) {
    if (qty <= 0) {
      remove(id);
      return;
    }
    state = [
      for (final e in state)
        e.productId == id
            ? e.copyWith(qty: qty > e.maxStock ? e.maxStock : qty)
            : e,
    ];
  }

  void remove(String id) =>
      state = state.where((e) => e.productId != id).toList();

  void clear() => state = const [];
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartTotalProvider = Provider<double>(
    (ref) => ref.watch(cartProvider).fold(0.0, (s, e) => s + e.subtotal));
