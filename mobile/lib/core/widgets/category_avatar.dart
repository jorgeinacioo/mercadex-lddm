import 'package:flutter/material.dart';
import 'package:mercadex/core/format/text.dart';

/// Product picture placeholder: an icon and a tint that follow the category.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 52});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: dark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        style.icon,
        size: size * 0.5,
        color: dark ? Color.lerp(style.color, Colors.white, 0.35) : style.color,
        semanticLabel: category.isEmpty ? null : category,
      ),
    );
  }
}

typedef CategoryStyle = ({IconData icon, Color color});

CategoryStyle categoryStyle(String category) {
  return switch (normalizeText(category)) {
    'hortifruti' => (icon: Icons.eco, color: const Color(0xFF16A34A)),
    'bebidas' => (icon: Icons.local_drink, color: const Color(0xFF0284C7)),
    'laticinios' => (icon: Icons.icecream, color: const Color(0xFF0D9488)),
    'carnes' => (icon: Icons.set_meal, color: const Color(0xFFDC2626)),
    'padaria' => (icon: Icons.bakery_dining, color: const Color(0xFFD97706)),
    'ovos' => (icon: Icons.egg, color: const Color(0xFFCA8A04)),
    'enlatados' => (icon: Icons.inventory_2, color: const Color(0xFF64748B)),
    'mercearia' => (icon: Icons.rice_bowl, color: const Color(0xFFB45309)),
    _ => (icon: Icons.shopping_bag, color: const Color(0xFF16A34A)),
  };
}
