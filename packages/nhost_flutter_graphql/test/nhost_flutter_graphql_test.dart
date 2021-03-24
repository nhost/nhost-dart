import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:nhost_sdk/client.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:nhost_flutter_graphql/nhost_flutter_graphql.dart';

const testGqlEndpoint = 'https://test/v1/graphql';

void main() {
  group('NhostGraphQLProvider', () {
    testWidgets('builds a GraphQLProvider from an NhostClient', (tester) async {
      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: testGqlEndpoint,
          nhostClient: MockNhostClient(),
          child: SizedBox(),
        ),
      );

      final gqlProviders =
          tester.widgetList<GraphQLProvider>(find.byType(GraphQLProvider));
      expect(gqlProviders, hasLength(1));
    });

    testWidgets(
        'repeated builds with identical information does not update the '
        'GraphQLClient', (tester) async {
      final nhost = MockNhostClient();

      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: testGqlEndpoint,
          nhostClient: nhost,
          child: SizedBox(),
        ),
      );
      final firstClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: testGqlEndpoint,
          nhostClient: nhost,
          child: SizedBox(),
        ),
      );
      final secondClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      expect(firstClient, secondClient);
    });

    testWidgets('repeated builds with different URLs updates the GraphQLClient',
        (tester) async {
      final nhost = MockNhostClient();

      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: testGqlEndpoint,
          nhostClient: nhost,
          child: SizedBox(),
        ),
      );
      final firstClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: 'https://test2/v1/graphql',
          nhostClient: nhost,
          child: SizedBox(),
        ),
      );
      final secondClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      expect(firstClient, isNot(secondClient));
    });

    testWidgets(
        'repeated builds with different NhostClients updates the GraphQLClient',
        (tester) async {
      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: testGqlEndpoint,
          nhostClient: MockNhostClient(),
          child: SizedBox(),
        ),
      );
      final firstClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: testGqlEndpoint,
          nhostClient: MockNhostClient(),
          child: SizedBox(),
        ),
      );
      final secondClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      expect(firstClient, isNot(secondClient));
    });

    testWidgets(
        'uses ancestor\'s authentication information if no client is provided',
        (tester) async {
      final nhost = MockNhostClient();
      await tester.pumpWidget(
        NhostAuthProvider(
          auth: nhost.auth,
          child: NhostGraphQLProvider(
            gqlEndpointUrl: testGqlEndpoint,
            child: SizedBox(),
          ),
        ),
      );

      final gqlProviders =
          tester.widgetList<GraphQLProvider>(find.byType(GraphQLProvider));
      expect(gqlProviders, hasLength(1));
    });

    testWidgets(
        'repeated builds with the same Auth ancestor does not update the '
        'GraphQLClient', (tester) async {
      final nhost = MockNhostClient();

      await tester.pumpWidget(
        NhostAuthProvider(
          auth: nhost.auth,
          child: NhostGraphQLProvider(
            gqlEndpointUrl: testGqlEndpoint,
            child: SizedBox(),
          ),
        ),
      );
      final firstClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      await tester.pumpWidget(
        NhostAuthProvider(
          auth: nhost.auth,
          child: NhostGraphQLProvider(
            gqlEndpointUrl: testGqlEndpoint,
            child: SizedBox(),
          ),
        ),
      );
      final secondClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      expect(firstClient, secondClient);
    });

    testWidgets(
        'repeated builds with different Auth ancestors updates the '
        'GraphQLClient', (tester) async {
      await tester.pumpWidget(
        NhostAuthProvider(
          auth: MockAuth(),
          child: NhostGraphQLProvider(
            gqlEndpointUrl: testGqlEndpoint,
            child: SizedBox(),
          ),
        ),
      );
      final firstClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      await tester.pumpWidget(
        NhostAuthProvider(
          auth: MockAuth(), // New auth object
          child: NhostGraphQLProvider(
            gqlEndpointUrl: testGqlEndpoint,
            child: SizedBox(),
          ),
        ),
      );
      final secondClient = tester
          .firstWidget<GraphQLProvider>(find.byType(GraphQLProvider))
          .client
          .value;

      expect(firstClient, isNot(secondClient));
    });

    testWidgets('fails if no authentication information can be found',
        (tester) async {
      await tester.pumpWidget(
        NhostGraphQLProvider(
          gqlEndpointUrl: testGqlEndpoint,
          child: SizedBox(),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isNot(null));
      expect(exception, isA<FlutterError>());

      final flutterError = exception as FlutterError;
      expect(flutterError.diagnostics, contains(isA<ErrorSummary>()));
      expect(flutterError.diagnostics, contains(isA<ErrorDescription>()));
    });
  });
}

class MockNhostClient extends Mock implements NhostClient {
  @override
  Auth get auth => _auth ??= MockAuth();
  Auth _auth;
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
