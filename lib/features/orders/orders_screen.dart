import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../data/models.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر تحميل الطلبات\n$e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('لا توجد طلبات بعد'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => OrderCard(order: list[i]),
          );
        },
      ),
    );
  }
}

/// بطاقة الطلب: تُستخدم للعميل ولـ المشرف (admin: true يظهر بيانات العميل وتغيير الحالة)
class OrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool admin;
  const OrderCard({super.key, required this.order, this.admin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortId =
        order.id.length >= 6 ? order.id.substring(0, 6) : order.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('طلب #$shortId',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Chip(
                    label:
                        Text(orderStatuses[order.status] ?? order.status)),
              ],
            ),
            Text(formatDate(order.createdAt)),
            const Divider(),
            for (final it in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                    '${it.qty} × ${it.name} — ${formatPrice(it.subtotal)}'),
              ),
            const Divider(),
            Text('الإجمالي: ${formatPrice(order.total)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('العنوان: ${order.address}'),
            if (order.notes.isNotEmpty) Text('ملاحظات: ${order.notes}'),
            if (admin) ...[
              const Divider(),
              Text('العميل: ${order.customerName}'),
              Row(
                children: [
                  Expanded(child: SelectableText('الهاتف: ${order.phone}')),
                  IconButton(
                    tooltip: 'اتصال',
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () => callPhone(order.phone),
                  ),
                  IconButton(
                    tooltip: 'واتساب',
                    icon: const Icon(Icons.message_outlined),
                    onPressed: () => openWhatsApp(
                        'مرحباً ${order.customerName}، بخصوص طلبك #$shortId',
                        phone: order.phone),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('الحالة: '),
                  DropdownButton<String>(
                    value: orderStatuses.containsKey(order.status)
                        ? order.status
                        : 'pending',
                    items: orderStatuses.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(orderRepoProvider)
                            .updateStatus(order.id, v);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
