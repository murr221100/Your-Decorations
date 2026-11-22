import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../widgets/product_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cartCount = ref.watch(cartProvider).fold<int>(0, (s, e) => s + e.qty);
    final user = ref.watch(authStateProvider).value;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.storeName),
        actions: [
          IconButton(
            tooltip: 'السلة',
            onPressed: () => context.push('/cart'),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          if (user == null)
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('دخول'),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (v) async {
                if (v == 'orders') context.push('/orders');
                if (v == 'admin') context.push('/admin');
                if (v == 'logout') await ref.read(authRepoProvider).signOut();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'orders', child: Text('طلباتي')),
                if (isAdmin)
                  const PopupMenuItem(value: 'admin', child: Text('لوحة التحكم')),
                const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('تعذر تحميل المنتجات\n$e')),
              data: (all) {
                final q = _query.trim().toLowerCase();
                final list =
                    all.where((p) => p.name.toLowerCase().contains(q)).toList();
                if (list.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ProductCard(product: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductImage(
                  url: product.images.isEmpty ? null : product.images.first),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    product.inStock ? formatPrice(product.price) : 'غير متوفر',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: product.inStock
                          ? Theme.of(context).colorScheme.primary
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
