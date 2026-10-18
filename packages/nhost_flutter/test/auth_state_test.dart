import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

void main() {
  group('AuthState sealed classes', () {
    test('AuthStateLoading is an AuthState', () {
      const AuthState state = AuthStateLoading();
      expect(state, isA<AuthStateLoading>());
    });

    test('AuthStateSignedOut is an AuthState', () {
      const AuthState state = AuthStateSignedOut();
      expect(state, isA<AuthStateSignedOut>());
    });

    test('AuthStateSignedIn carries user and session', () {
      final user = makeTestUser();
      final session = makeTestSession();
      final AuthState state = AuthStateSignedIn(user: user, session: session);

      expect(state, isA<AuthStateSignedIn>());
      expect((state as AuthStateSignedIn).user.email, 'ada@example.com');
      expect(state.session.accessToken, 'tok');
    });

    test('exhaustive switch compiles without default', () {
      const AuthState state = AuthStateLoading();
      final label = switch (state) {
        AuthStateLoading() => 'loading',
        AuthStateSignedOut() => 'out',
        AuthStateSignedIn() => 'in',
      };
      expect(label, 'loading');
    });
  });
}

User makeTestUser() => User(
      id: 'u1',
      displayName: 'Ada',
      locale: 'en',
      createdAt: DateTime.utc(2024),
      isAnonymous: false,
      defaultRole: 'user',
      roles: const ['user'],
      emailVerified: true,
      phoneNumber: '',
      phoneNumberVerified: false,
      email: 'ada@example.com',
    );

Session makeTestSession() => Session(
      accessToken: 'tok',
      accessTokenExpiresIn: const Duration(seconds: 900),
      refreshToken: 'ref',
      user: makeTestUser(),
    );
