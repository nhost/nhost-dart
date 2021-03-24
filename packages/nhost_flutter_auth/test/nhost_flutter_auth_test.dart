import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

void main() {
  group('NhostAuthProvider', () {
    testWidgets('exposes authentication information to its subtree',
        (tester) async {
      final mockAuth = MockAuth();

      Auth? actualAuth;
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
          auth: MockAuth(), // Brand new MockAuth(), which triggers a change
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
          auth: consistentAuth, // Brand new MockAuth(), which triggers a change
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
      mockAuth.triggerStateChange();
      await tester.pump();

      // The state change should result in a second build
      expect(buildCount, 2);
    });

    testWidgets('.of() returns null if no authentication found',
        (tester) async {
      // We set it to a value to ensure it gets changed
      Auth? auth = MockAuth();
      await tester.pumpWidget(
        Builder(builder: (context) {
          auth = NhostAuthProvider.of(context);
          return SizedBox();
        }),
      );

      expect(auth, isNull);
    });
  });
}

class MockAuth extends Mock implements Auth {
  final List<TokenChangedCallback> _tokenChangedCallbacks = [];

  @override
  UnsubscribeDelegate addTokenChangedCallback(TokenChangedCallback callback) {
    _tokenChangedCallbacks.add(callback);
    return () {
      _tokenChangedCallbacks.removeWhere((element) => element == callback);
    };
  }

  void triggerStateChange() {
    for (final callback in _tokenChangedCallbacks) {
      callback();
    }
  }
}
