import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const ProductImage({super.key, this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
