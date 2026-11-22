import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../data/models.dart';

class InquirySheet extends ConsumerStatefulWidget {
  final Product? product;
  const InquirySheet({super.key, this.product});

  @override
  ConsumerState<InquirySheet> createState() => _InquirySheetState();
}

class _InquirySheetState extends ConsumerState<InquirySheet> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(inquiryRepoProvider).send(Inquiry(
            id: '',
            userId: user.id,
            name: userNameOf(user),
            email: user.email ?? '',
            phone: _phone.text.trim(),
            message: _message.text.trim(),
            productId: widget.product?.id,
            productName: widget.product?.name,
          ));
      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('تم إرسال استفسارك، سنرد عليك قريباً')));
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        messenger.showSnackBar(SnackBar(content: Text('تعذر الإرسال: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.product == null
                  ? 'أرسل استفسارك'
                  : 'استفسار عن: ${widget.product!.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'رقم الهاتف للتواصل',
                  border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'أدخل رقم هاتف صحيح'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'رسالتك', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب رسالتك' : null,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}
