// Money is handled as integer cents to avoid floating point rounding.

/// Parses a decimal string from the API or the catalog ("8.99") into cents.
int parseCents(String value) {
  final match = RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$').firstMatch(value.trim());
  if (match == null) {
    throw FormatException('Preço inválido: $value');
  }
  final reais = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '0').padRight(2, '0');
  return reais * 100 + int.parse(fraction);
}

/// Formats cents as Brazilian currency, e.g. 123456 -> "R$ 1.234,56".
String formatBrl(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final reais = (absolute ~/ 100).toString();
  final centavos = (absolute % 100).toString().padLeft(2, '0');
  final grouped = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) grouped.write('.');
    grouped.write(reais[i]);
  }
  return '${negative ? '-' : ''}R\$ $grouped,$centavos';
}

/// Cents as a plain decimal string, e.g. 899 -> "8.99" (for the API).
String formatDecimal(int cents) {
  return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
}

/// Parses what the user typed ("4,29", "4.29", "4") into cents.
/// Returns null for anything that is not a positive amount with up to two
/// decimal places.
int? parseUserPrice(String input) {
  final text = input.trim().replaceAll('R\$', '').trim();
  if (!RegExp(r'^\d{1,5}([.,]\d{1,2})?$').hasMatch(text)) return null;
  final cents = parseCents(text);
  return cents > 0 ? cents : null;
}
