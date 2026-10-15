import 'package:flutter/material.dart';
import 'package:mercadex/core/theme/app_colors.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.hintText = 'Buscar produtos',
    this.initialValue,
    this.onSubmitted,
  });

  final String hintText;
  final String? initialValue;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onFieldSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
      ),
    );
  }
}
