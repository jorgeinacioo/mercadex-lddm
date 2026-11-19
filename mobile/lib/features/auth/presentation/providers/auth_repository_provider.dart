import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const AuthRepository(),
);
