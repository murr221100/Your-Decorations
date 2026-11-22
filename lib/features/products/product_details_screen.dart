import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../widgets/product_image.dart';
import '../contact/inquiry_sheet.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductDetailsScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _page = 0;

  void _addToCart(Product p) {
    ref.read(cartProvider.notifier).add(p);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تمت الإضافة إلى السلة'),
        action: SnackBarAction(
            label: 'عرض السلة', onPressed: () => context.push('/cart')),
      ),
    );
  }

  void _inquire(Product p) {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      context.push(loginPath('/product/${p.id}'));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => InquirySheet(product: p),
    );
  }

  Widget _gallery(Product p) {
    if (p.images.isEmpty) {
      return const SizedBox(height: 300, child: ProductImage(url: null));
    }
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: p.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => ProductImage(url: p.images[i]),
          ),
          if (p.images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < p.images.length; i++)
                    Container(
                      margin: const EdgeInsets.all(3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page ? Colors.teal : Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productProvider(widget.id));
    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر تحميل المنتج\n$e')),
        data: (p) {
          if (p == null) return const Center(child: Text('المنتج غير موجود'));
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _gallery(p),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            formatPrice(p.price),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                                p.inStock ? 'متوفر (${p.stock})' : 'غير متوفر'),
                          ),
                          const SizedBox(height: 12),
                          Text(p.description),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: p.inStock ? () => _addToCart(p) : null,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('أضف إلى السلة'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _inquire(p),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('استفسر'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => openWhatsApp(
                                  'مرحباً، أرغب في الاستفسار عن: ${p.name}'),
                              icon: const Icon(Icons.message_outlined),
                              label: const Text('واتساب'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
