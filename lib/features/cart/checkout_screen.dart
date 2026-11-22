import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../data/models.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
        text: userNameOf(ref.read(authStateProvider).value));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    final items = ref.read(cartProvider);
    if (user == null || items.isEmpty) return;

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(orderRepoProvider).placeOrder(OrderModel(
            id: '',
            userId: user.id,
            userEmail: user.email ?? '',
            customerName: _name.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
            notes: _notes.text.trim(),
            paymentMethod: 'cod',
            status: 'pending',
            items: items,
            total: ref.read(cartTotalProvider),
          ));
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تم استلام طلبك ✅'),
          content: const Text('سنتواصل معك قريباً لتأكيد الطلب وموعد التوصيل.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً')),
          ],
        ),
      );
      if (mounted) context.go('/orders');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذر إرسال الطلب: $e')));
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: items.isEmpty
          ? const Center(child: Text('السلة فارغة'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                            labelText: 'الاسم', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'أدخل الاسم'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().length < 8)
                            ? 'أدخل رقم هاتف صحيح'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'عنوان التوصيل بالتفصيل',
                            border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().length < 8)
                            ? 'أدخل العنوان بالتفصيل'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.payments_outlined),
                          title: Text('طريقة الدفع'),
                          subtitle: Text('الدفع عند الاستلام'),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('تأكيد الطلب'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
