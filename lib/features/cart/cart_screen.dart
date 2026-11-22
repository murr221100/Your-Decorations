import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../widgets/product_image.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('سلة المشتريات')),
      body: items.isEmpty
          ? const Center(child: Text('السلة فارغة'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return Row(
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ProductImage(url: it.image),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                Text(formatPrice(it.subtotal),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                cart.setQty(it.productId, it.qty - 1),
                          ),
                          Text('${it.qty}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: it.qty < it.maxStock
                                ? () => cart.setQty(it.productId, it.qty + 1)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cart.remove(it.productId),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الإجمالي',
                                style: TextStyle(fontSize: 16)),
                            Text(formatPrice(total),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => context.push('/checkout'),
                          child: const Text('إتمام الطلب'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
