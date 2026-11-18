import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.hintText = 'Buscar produtos',
    this.initialValue,
    this.onSubmitted,
    this.onScan,
    this.autofocus = false,
  });

  final String hintText;
  final String? initialValue;
  final ValueChanged<String>? onSubmitted;

  /// When set, shows a barcode button inside the field.
  final VoidCallback? onScan;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      initialValue: initialValue,
      autofocus: autofocus,
      onFieldSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
        suffixIcon: onScan == null
            ? null
            : IconButton(
                tooltip: 'Escanear código de barras',
                onPressed: onScan,
                icon: Icon(Icons.qr_code_scanner, color: scheme.primary),
              ),
      ),
    );
  }
}
