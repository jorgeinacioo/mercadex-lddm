import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/auth/data/auth_session_storage.dart';
import 'package:mercadex/features/auth/domain/auth_session.dart';

final authSessionProvider = NotifierProvider<AuthSessionNotifier, AuthSession?>(
  AuthSessionNotifier.new,
);

class AuthSessionNotifier extends Notifier<AuthSession?> {
  AuthSessionNotifier({
    this.initialSession,
    AuthSessionStorage? storage,
  }) : _storage = storage ?? const SecureAuthSessionStorage();

  final AuthSession? initialSession;
  final AuthSessionStorage _storage;

  @override
  AuthSession? build() => initialSession;

  Future<void> logIn({
    required String username,
    required String accessToken,
  }) async {
    final session = AuthSession(username: username, accessToken: accessToken);
    await _storage.write(session);
    state = session;
  }

  Future<void> logOut() async {
    await _storage.clear();
    state = null;
  }
}
