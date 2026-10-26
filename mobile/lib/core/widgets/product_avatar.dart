import 'package:flutter/material.dart';

class ProductAvatar extends StatelessWidget {
  const ProductAvatar({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        Icons.shopping_bag,
        color: Theme.of(context).colorScheme.primary,
        size: size * 0.46,
      ),
    );
  }
}
