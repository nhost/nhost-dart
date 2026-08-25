import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

import '../helpers/fake_auth_client.dart';

Widget _wrap(FakeAuthClient auth, Widget child) =>
    MaterialApp(home: NhostAuthProvider(auth: auth, child: child));

void main() {
  group('NhostSignedIn', () {
    testWidgets('shows child when signed in', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedIn)
        ..simulateSignIn(makeUser(), makeSession());
      await tester.pumpWidget(
          _wrap(auth, const NhostSignedIn(child: Text('admin'))));
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('hides child when signed out', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(
          _wrap(auth, const NhostSignedIn(child: Text('admin'))));
      expect(find.text('admin'), findsNothing);
    });

    testWidgets('shows orElse when signed out and orElse provided',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(_wrap(
        auth,
        const NhostSignedIn(child: Text('admin'), orElse: Text('guest')),
      ));
      expect(find.text('guest'), findsOneWidget);
      expect(find.text('admin'), findsNothing);
    });
  });

  group('NhostSignedOut', () {
    testWidgets('shows child when signed out', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(
          _wrap(auth, const NhostSignedOut(child: Text('login'))));
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('hides child when signed in', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedIn)
        ..simulateSignIn(makeUser(), makeSession());
      await tester.pumpWidget(
          _wrap(auth, const NhostSignedOut(child: Text('login'))));
      expect(find.text('login'), findsNothing);
    });

    testWidgets('shows orElse when signed in and orElse provided',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedIn)
        ..simulateSignIn(makeUser(), makeSession());
      await tester.pumpWidget(_wrap(
        auth,
        const NhostSignedOut(
            child: Text('login'), orElse: Text('dashboard')),
      ));
      expect(find.text('dashboard'), findsOneWidget);
      expect(find.text('login'), findsNothing);
    });
  });
}
