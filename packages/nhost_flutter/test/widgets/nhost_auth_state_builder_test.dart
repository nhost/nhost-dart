import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

import '../helpers/fake_auth_client.dart';

Widget _wrap(FakeAuthClient auth, Widget child) =>
    MaterialApp(home: NhostAuthProvider(auth: auth, child: child));

void main() {
  group('NhostAuthStateBuilder', () {
    testWidgets('passes AuthStateSignedOut when signed out', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      AuthState? received;
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthStateBuilder(builder: (_, state) {
          received = state;
          return const SizedBox();
        }),
      ));
      expect(received, isA<AuthStateSignedOut>());
    });

    testWidgets('passes AuthStateLoading when inProgress', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.inProgress);
      AuthState? received;
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthStateBuilder(builder: (_, state) {
          received = state;
          return const SizedBox();
        }),
      ));
      expect(received, isA<AuthStateLoading>());
    });

    testWidgets('passes AuthStateSignedIn with user when signed in',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedIn)
        ..simulateSignIn(makeUser(email: 'x@y.com'), makeSession());
      AuthState? received;
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthStateBuilder(builder: (_, state) {
          received = state;
          return const SizedBox();
        }),
      ));
      expect(received, isA<AuthStateSignedIn>());
      expect((received as AuthStateSignedIn).user.email, 'x@y.com');
    });

    testWidgets('rebuilds when auth state changes', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      final states = <AuthState>[];
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthStateBuilder(builder: (_, state) {
          states.add(state);
          return const SizedBox();
        }),
      ));

      auth.simulateSignIn(makeUser(), makeSession());
      await tester.pump();

      expect(states.length, 2);
      expect(states[0], isA<AuthStateSignedOut>());
      expect(states[1], isA<AuthStateSignedIn>());
    });
  });
}
