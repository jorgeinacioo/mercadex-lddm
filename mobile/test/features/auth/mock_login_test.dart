import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/features/auth/data/auth_repository.dart';

void main() {
  const repository = AuthRepository();

  test('mock login accepts admin credentials', () async {
    expect(
      await repository.login(username: 'admin', password: 'admin'),
      'mock-access-token',
    );
  });

  test('mock login rejects wrong username and password', () async {
    await expectLater(
      repository.login(username: 'someone', password: 'admin'),
      throwsFormatException,
    );
    await expectLater(
      repository.login(username: 'admin', password: 'wrong'),
      throwsFormatException,
    );
  });
}
