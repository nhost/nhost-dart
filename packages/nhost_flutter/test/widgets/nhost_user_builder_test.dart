import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

import '../helpers/fake_auth_client.dart';

Widget _wrap(FakeAuthClient auth, Widget child) =>
    MaterialApp(home: NhostAuthProvider(auth: auth, child: child));

void main() {
  group('NhostUserBuilder', () {
    testWidgets('calls builder with current user when signed in',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedIn)
        ..simulateSignIn(makeUser(email: 'ada@example.com'), makeSession());
      await tester.pumpWidget(_wrap(
        auth,
        NhostUserBuilder(
          builder: (_, user) => Text('hi ${user.email}'),
        ),
      ));
      expect(find.text('hi ada@example.com'), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when signed out and no orElse',
        (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(_wrap(
        auth,
        NhostUserBuilder(builder: (_, user) => Text('hi ${user.email}')),
      ));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders orElse when signed out', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(_wrap(
        auth,
        NhostUserBuilder(
          builder: (_, user) => Text('hi ${user.email}'),
          orElse: (_) => const Text('please sign in'),
        ),
      ));
      expect(find.text('please sign in'), findsOneWidget);
    });

    testWidgets('rebuilds when user signs in', (tester) async {
      final auth = FakeAuthClient(AuthenticationState.signedOut);
      await tester.pumpWidget(_wrap(
        auth,
        NhostUserBuilder(
          builder: (_, user) => Text('hi ${user.email}'),
          orElse: (_) => const Text('signed out'),
        ),
      ));
      expect(find.text('signed out'), findsOneWidget);

      auth.simulateSignIn(makeUser(email: 'b@c.com'), makeSession());
      await tester.pump();

      expect(find.text('hi b@c.com'), findsOneWidget);
    });
  });
}
