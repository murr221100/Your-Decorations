import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../data/models.dart';
import '../../widgets/product_image.dart';

class _NewImage {
  final XFile file;
  final Uint8List bytes;
  _NewImage(this.file, this.bytes);
}

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final List<String> _kept;
  final List<_NewImage> _new = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p == null ? '' : '${p.price}');
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _kept = [...(p?.images ?? const <String>[])];
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final files =
        await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600);
    final added = <_NewImage>[];
    for (final f in files) {
      added.add(_NewImage(f, await f.readAsBytes()));
    }
    if (mounted) setState(() => _new.addAll(added));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    if (_kept.isEmpty && _new.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('أضف صورة واحدة على الأقل')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(productRepoProvider).save(
            existing: widget.product,
            name: _name.text.trim(),
            description: _desc.text.trim(),
            price: double.parse(_price.text.replaceAll(',', '.')),
            stock: int.parse(_stock.text),
            keptImages: _kept,
            newImages: _new.map((e) => e.file).toList(),
          );
      if (mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _thumb(Widget image, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(left: 8),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 14, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.product == null ? 'منتج جديد' : 'تعديل المنتج')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final url in _kept)
                        _thumb(ProductImage(url: url),
                            () => setState(() => _kept.remove(url))),
                      for (final n in _new)
                        _thumb(Image.memory(n.bytes, fit: BoxFit.cover),
                            () => setState(() => _new.remove(n))),
                      InkWell(
                        onTap: _pick,
                        child: Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined,
                              size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'اسم المنتج', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'الوصف', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'السعر', border: OutlineInputBorder()),
                  validator: (v) =>
                      double.tryParse((v ?? '').replaceAll(',', '.')) == null
                          ? 'أدخل سعراً صحيحاً'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'الكمية المتوفرة', border: OutlineInputBorder()),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'أدخل رقماً صحيحاً' : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
