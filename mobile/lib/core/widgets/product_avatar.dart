import 'package:flutter/material.dart';
import 'package:mercadex/core/theme/app_colors.dart';

class ProductAvatar extends StatelessWidget {
  const ProductAvatar({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.primary,
        size: size * 0.46,
      ),
    );
  }
}
