import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/format/relative_time.dart';
import 'package:mercadex/core/format/text.dart';

void main() {
  test('parses API prices into cents without floating point errors', () {
    expect(parseCents('8.99'), 899);
    expect(parseCents('0.1'), 10);
    expect(parseCents('29'), 2900);
    expect(parseCents('1234.56'), 123456);
    expect(() => parseCents('abc'), throwsFormatException);
  });

  test('formats cents as Brazilian currency', () {
    expect(formatBrl(899), 'R\$ 8,99');
    expect(formatBrl(5), 'R\$ 0,05');
    expect(formatBrl(123456789), 'R\$ 1.234.567,89');
    expect(formatDecimal(1549), '15.49');
  });

  test('accepts prices typed with comma or dot, up to two decimals', () {
    expect(parseUserPrice('4,29'), 429);
    expect(parseUserPrice(' 4.2 '), 420);
    expect(parseUserPrice('R\$ 10'), 1000);
    expect(parseUserPrice('0'), isNull);
    expect(parseUserPrice('4,299'), isNull);
    expect(parseUserPrice('-3'), isNull);
    expect(parseUserPrice(''), isNull);
  });

  test('normalizes accents for search', () {
    expect(normalizeText('  Café com AÇÚCAR '), 'cafe com acucar');
    expect(normalizeText('Pão de Açúcar'), 'pao de acucar');
  });

  test('describes how long ago a price was reported', () {
    final now = DateTime(2026, 11, 20, 12);
    expect(relativeTime(now, now: now), 'agora');
    expect(
      relativeTime(now.subtract(const Duration(minutes: 5)), now: now),
      'há 5 min',
    );
    expect(
      relativeTime(now.subtract(const Duration(hours: 3)), now: now),
      'há 3 h',
    );
    expect(
      relativeTime(now.subtract(const Duration(days: 1)), now: now),
      'ontem',
    );
    expect(relativeTime(DateTime(2026, 9, 2), now: now), 'em 02/09/2026');
  });
}
