import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../widgets/product_image.dart';
import '../orders/orders_screen.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(isAdminProvider);
    return adminAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('$e'))),
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('لوحة التحكم')),
            body: const Center(child: Text('هذه الصفحة للمشرف فقط')),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('لوحة التحكم'),
              bottom: const TabBar(tabs: [
                Tab(text: 'المنتجات'),
                Tab(text: 'الطلبات'),
                Tab(text: 'الاستفسارات'),
              ]),
            ),
            body: const TabBarView(children: [
              _ProductsTab(),
              _OrdersTab(),
              _InquiriesTab(),
            ]),
          ),
        );
      },
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل تريد حذف "${p.name}" نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) await ref.read(productRepoProvider).delete(p);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FilledButton.icon(
            onPressed: () => context.push('/admin/product'),
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج جديد'),
          ),
          const SizedBox(height: 8),
          for (final p in list)
            Card(
              child: ListTile(
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ProductImage(
                        url: p.images.isEmpty ? null : p.images.first),
                  ),
                ),
                title: Text(p.name),
                subtitle:
                    Text('${formatPrice(p.price)} • المخزون: ${p.stock}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/admin/product', extra: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, p),
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

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);
    return orders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('لا توجد طلبات'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => OrderCard(order: list[i], admin: true),
        );
      },
    );
  }
}

class _InquiriesTab extends ConsumerWidget {
  const _InquiriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiries = ref.watch(inquiriesProvider);
    return inquiries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('لا توجد استفسارات'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final q = list[i];
            return Card(
              child: ListTile(
                isThreeLine: true,
                title: Text(
                    '${q.name}${q.productName != null ? ' — ${q.productName}' : ''}'),
                subtitle: Text(
                    '${q.message}\n${q.phone} • ${q.email} • ${formatDate(q.createdAt)}'),
                trailing: q.phone.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'رد عبر واتساب',
                        icon: const Icon(Icons.message_outlined),
                        onPressed: () => openWhatsApp(
                            'مرحباً ${q.name}، بخصوص استفسارك${q.productName != null ? ' عن ${q.productName}' : ''}',
                            phone: q.phone),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
