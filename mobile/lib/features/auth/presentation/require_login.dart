import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';

/// Opens the login page when needed. Returns true once the user is signed in.
Future<bool> requireLogin(BuildContext context, WidgetRef ref) async {
  if (ref.read(authSessionProvider) != null) return true;
  final loggedIn = await context.push<bool>('/login?reason=contribute');
  return loggedIn == true && ref.read(authSessionProvider) != null;
}
