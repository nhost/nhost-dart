import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

import '../helpers/fake_auth_client.dart';

Widget _wrap(FakeAuthClient auth, Widget child) => MaterialApp(
      home: NhostAuthProvider(auth: auth, child: child),
    );

void main() {
  group('NhostAuthGate', () {
    testWidgets('shows signedOut widget when signed out', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthGate(
          signedOut: (_) => const Text('login'),
          signedIn: (_, __, ___) => const Text('home'),
        ),
      ));
      expect(find.text('login'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });

    testWidgets('shows signedIn widget with user when signed in',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedIn)
        ..simulateSignIn(makeUser(), makeSession());
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthGate(
          signedOut: (_) => const Text('login'),
          signedIn: (_, user, __) => Text('home:${user.email}'),
        ),
      ));
      expect(find.text('home:test@example.com'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink when loading and no loading builder',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.inProgress);
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthGate(
          signedOut: (_) => const Text('login'),
          signedIn: (_, __, ___) => const Text('home'),
        ),
      ));
      expect(find.text('login'), findsNothing);
      expect(find.text('home'), findsNothing);
    });

    testWidgets('shows loading widget when provided and inProgress',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.inProgress);
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthGate(
          loading: (_) => const Text('loading'),
          signedOut: (_) => const Text('login'),
          signedIn: (_, __, ___) => const Text('home'),
        ),
      ));
      expect(find.text('loading'), findsOneWidget);
    });

    testWidgets('switches widget when auth state changes', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(_wrap(
        auth,
        NhostAuthGate(
          signedOut: (_) => const Text('login'),
          signedIn: (_, __, ___) => const Text('home'),
        ),
      ));
      expect(find.text('login'), findsOneWidget);

      auth.simulateSignIn(makeUser(), makeSession());
      await tester.pump();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('login'), findsNothing);
    });
  });
}
