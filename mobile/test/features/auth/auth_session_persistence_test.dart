import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/auth/data/auth_session_storage.dart';
import 'package:mercadex/features/auth/domain/auth_session.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';

class MemoryAuthSessionStorage implements AuthSessionStorage {
  AuthSession? session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}

void main() {
  test('login survives a new provider and logout clears the saved session', () async {
    final storage = MemoryAuthSessionStorage();
    final first = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(
          () => AuthSessionNotifier(storage: storage),
        ),
      ],
    );
    await first.read(authSessionProvider.notifier).logIn(
      username: 'admin',
      accessToken: 'test-token',
    );
    expect(storage.session?.username, 'admin');
    first.dispose();

    final second = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(
          () => AuthSessionNotifier(
            initialSession: storage.session,
            storage: storage,
          ),
        ),
      ],
    );
    expect(second.read(authSessionProvider)?.username, 'admin');
    await second.read(authSessionProvider.notifier).logOut();
    expect(second.read(authSessionProvider), isNull);
    expect(await storage.read(), isNull);
    second.dispose();
  });
}
