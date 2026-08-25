import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

import 'helpers/fake_auth_client.dart';

void main() {
  group('NhostAuthClientFlutterX', () {
    late FakeAuthClient auth;

    setUp(() {
      auth = FakeAuthClient(AuthenticationState.signedOut);
    });

    group('authStateChanges stream', () {
      test('emits AuthStateSignedIn when client fires signedIn callback',
          () async {
        final states = <AuthState>[];
        final sub = auth.authStateChanges.listen(states.add);
        addTearDown(sub.cancel);

        auth.simulateSignIn(makeUser(), makeSession());

        await Future.microtask(() {});
        expect(states, [isA<AuthStateSignedIn>()]);
        expect((states.first as AuthStateSignedIn).user.email,
            'test@example.com');
      });

      test('emits AuthStateSignedOut when client fires signedOut callback',
          () async {
        auth = FakeAuthClient(AuthenticationState.signedIn)
          ..simulateSignIn(makeUser(), makeSession());

        final states = <AuthState>[];
        final sub = auth.authStateChanges.listen(states.add);
        addTearDown(sub.cancel);

        auth.simulateSignOut();

        await Future.microtask(() {});
        expect(states, [isA<AuthStateSignedOut>()]);
      });

      test('is a broadcast stream — multiple listeners allowed', () async {
        final sub1 = auth.authStateChanges.listen((_) {});
        final sub2 = auth.authStateChanges.listen((_) {});
        addTearDown(sub1.cancel);
        addTearDown(sub2.cancel);
        expect(() => auth.authStateChanges, returnsNormally);
      });
    });

    group('authStateListenable', () {
      test('initial value reflects signedOut state', () {
        expect(auth.authStateListenable.value, isA<AuthStateSignedOut>());
      });

      test('notifies listeners on state change', () {
        final notifier =
            auth.authStateListenable as ValueNotifier<AuthState>;
        var notified = false;
        notifier.addListener(() => notified = true);

        auth.simulateSignIn(makeUser(), makeSession());

        expect(notified, isTrue);
        expect(notifier.value, isA<AuthStateSignedIn>());
      });
    });
  });
}
