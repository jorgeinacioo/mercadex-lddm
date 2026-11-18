import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/prices/data/prices_repository.dart';

final pricesRepositoryProvider = Provider<PricesRepository>(
  (ref) => const PricesRepository(),
);
