import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

void main() {
  group('NhostAuthProvider', () {
    testWidgets('exposes authentication information to its subtree',
        (tester) async {
      final mockAuth = MockAuth();

      Auth actualAuth;
      await tester.pumpWidget(
        NhostAuthProvider(
          auth: mockAuth,
          child: Builder(builder: (context) {
            actualAuth = NhostAuthProvider.of(context);
            return SizedBox();
          }),
        ),
      );

      expect(actualAuth, mockAuth);
    });

    testWidgets('rebuilds subtrees when the auth argument changes',
        (tester) async {
      var buildCount = 0;
      final countingBuilder = Builder(builder: (context) {
        NhostAuthProvider.of(context); // Establish dependency
        buildCount++;
        return SizedBox();
      });

      await tester.pumpWidget(
        NhostAuthProvider(
          auth: MockAuth(),
          child: countingBuilder,
        ),
      );
      expect(buildCount, 1);

      await tester.pumpWidget(
        NhostAuthProvider(
          auth:
              MockAuth(), // Brand new MockAuth(), which triggers a change
          child: countingBuilder,
        ),
      );
      expect(buildCount, 2);
    });

    testWidgets('does not rebuild when same argument provided repeatedly',
        (tester) async {
      var buildCount = 0;
      final countingBuilder = Builder(builder: (context) {
        NhostAuthProvider.of(context); // Establish dependency
        buildCount++;
        return SizedBox();
      });

      final consistentAuth = MockAuth();

      await tester.pumpWidget(
        NhostAuthProvider(
          auth: consistentAuth,
          child: countingBuilder,
        ),
      );
      expect(buildCount, 1);

      await tester.pumpWidget(
        NhostAuthProvider(
          auth:
              consistentAuth, // Brand new MockAuth(), which triggers a change
          child: countingBuilder,
        ),
      );
      expect(buildCount, 1);
    });

    testWidgets('rebuilds subtrees when the auth state changes',
        (tester) async {
      final mockAuth = MockAuth();

      var buildCount = 0;
      await tester.pumpWidget(
        NhostAuthProvider(
          auth: mockAuth,
          child: Builder(builder: (context) {
            NhostAuthProvider.of(context); // Establish dependency
            buildCount++;
            return SizedBox();
          }),
        ),
      );

      // We expect a single build after the initial render
      expect(buildCount, 1);

      // Emulate an auth state change, then pump the engine
      mockAuth.triggerStateChange(authenticated: true);
      await tester.pump();

      // The state change should result in a second build
      expect(buildCount, 2);
    });
  });
}

class MockAuth extends Mock implements Auth {
  final List<AuthStateChangedCallback> _authChangedFunctions = [];

  @override
  UnsubscribeDelegate addAuthStateChangedCallback(
      AuthStateChangedCallback callback) {
    _authChangedFunctions.add(callback);
    return () {
      _authChangedFunctions.removeWhere((element) => element == callback);
    };
  }

  void triggerStateChange({@required bool authenticated}) {
    for (final authChangedFunction in _authChangedFunctions) {
      authChangedFunction(authenticated: authenticated);
    }
  }
}
