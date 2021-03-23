import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:graphql/client.dart';
import 'package:nhost_sdk/client.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';
import 'package:nock/nock.dart';
import 'package:test/test.dart';

import 'mock_web_socket.dart';
import 'test_helpers.dart';

const baseUrl = 'https://test';
const backendEndpoint = '$baseUrl';

const gqlEndpointPath = '/v1/graphql';
const gqlEndpoint = '$baseUrl$gqlEndpointPath';

final testQuery = gql('query todos { id }');
const testJwt = 'eyJhbGciOiJIUzI1NiJ9.'
    'eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLXVzZXItaWQiOiJmMmZhMWJjNS03YmI5LTRjYjgtOTg5Ny0yZWQxMjhiN2I1YjkiLCJ4LWhhc3VyYS1hbGxvd2VkLXJvbGVzIjpbInVzZXIiXSwieC1oYXN1cmEtZGVmYXVsdC1yb2xlIjoidXNlciJ9LCJpYXQiOjE2MTU5OTk3NDksImV4cCI6MTYxNjAwMDY0OX0.'
    '1gDRrG8OYtjAzgSYWd2RzdYRKhaFG_3HBkpfVbSzk_w';
final testSession = Session(
  jwtToken: testJwt,
  jwtExpiresIn: Duration(days: 1),
  refreshToken: 'abcd',
);

void main() {
  NhostClient nhost;
  setUp(() {
    nhost = NhostClient(baseUrl: backendEndpoint);
  });

  tearDown(() {
    nhost.close();
  });

  group('http links', () {
    setUpAll(() {
      nock.init();
    });

    setUp(() {
      nock.cleanAll();
    });

    tearDownAll(() {
      HttpOverrides.global = null;
    });

    test('authenticated clients send auth headers', () async {
      final expectedHeaders = {
        'authorization': 'Bearer $testJwt',
      };

      // Set up the expectation
      final interceptor = nock(baseUrl).post(gqlEndpointPath, anything)
        ..headers(expectedHeaders)
        ..reply(200, null);

      // Fake authentication with Nhost
      await nhost.auth.setSession(testSession);

      // Perform a query
      final gqlClient = createNhostGraphQLClient(gqlEndpoint, nhost);
      await gqlClient.query(QueryOptions(document: testQuery));

      // Check if the interceptor matched
      expect(interceptor.isDone, true);
    });

    test('unauthenticated clients do not send auth headers', () async {
      final expectedHeaders = {
        // This is equivalent to the authentication header being absent
        'authentication': null,
      };

      // Set up the expectation
      final interceptor = nock(baseUrl).post(gqlEndpointPath, anything)
        ..headers(expectedHeaders)
        ..reply(200, null);

      // Perform a query
      final gqlClient = createNhostGraphQLClient(gqlEndpoint, nhost);
      await gqlClient.query(QueryOptions(document: testQuery));

      // Check if the interceptor matched
      expect(interceptor.isDone, true);
    });

    test('default headers are provided in request', () async {
      final expectedHeaders = {
        'x-hasura-role': 'superuser',
      };

      // Set up the expectation
      final interceptor = nock(baseUrl).post(gqlEndpointPath, anything)
        ..headers(expectedHeaders)
        ..reply(200, null);

      // Perform a query
      final gqlClient = createNhostGraphQLClient(
        gqlEndpoint,
        nhost,
        defaultHeaders: expectedHeaders,
      );
      await gqlClient.query(QueryOptions(document: testQuery));

      // Check if the interceptor matched
      expect(interceptor.isDone, true);
    });
  });

  group('web socket links', () {
    MockWebSocket mockWebSocket;

    setUp(() {
      mockWebSocket = MockWebSocket.connect();
    });

    tearDown(() {
      mockWebSocket.tearDown();
    });

    test('authenticated clients send auth headers', silencePrints(() async {
      final expectedHeaders = {
        'Authorization': 'Bearer $testJwt',
      };

      // Fake authentication with Nhost
      await nhost.auth.setSession(testSession);

      // Perform a query
      final gqlClient = GraphQLClient(
        link: webSocketLinkForNhost(
          gqlEndpoint,
          nhost.auth,
          testWebSocketConnectOverride: (uri, protocols) {
            return mockWebSocket;
          },
        ),
        cache: GraphQLCache(),
      );
      await gqlClient.query(QueryOptions(document: testQuery));

      // Ensure headers were sent
      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(initPayload['payload']['headers'], equals(expectedHeaders));
    }));

    test('unauthenticated clients do not send auth headers',
        silencePrints(() async {
      final expectedHeaders = {};

      // Perform a query
      final gqlClient = GraphQLClient(
        link: webSocketLinkForNhost(
          gqlEndpoint,
          nhost.auth,
          testWebSocketConnectOverride: (uri, protocols) {
            return mockWebSocket;
          },
        ),
        cache: GraphQLCache(),
      );
      await gqlClient.query(QueryOptions(document: testQuery));

      // Ensure no headers were sent
      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(initPayload['payload']['headers'], equals(expectedHeaders));
    }));

    test('default headers are provided in request', silencePrints(() async {
      final expectedHeaders = {
        'x-hasura-role': 'superuser',
      };

      // Perform a query
      final gqlClient = GraphQLClient(
        link: webSocketLinkForNhost(
          gqlEndpoint,
          nhost.auth,
          defaultHeaders: expectedHeaders,
          testWebSocketConnectOverride: (uri, protocols) {
            return mockWebSocket;
          },
        ),
        cache: GraphQLCache(),
      );
      await gqlClient.query(QueryOptions(document: testQuery));

      // Ensure headers were sent
      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(initPayload['payload']['headers'], equals(expectedHeaders));
    }));

    test('reconnects on auth changes', silencePrints(() async {
      var connectionCount = 0;
      final gqlClient = GraphQLClient(
        link: webSocketLinkForNhost(
          gqlEndpoint,
          nhost.auth,
          testWebSocketConnectOverride: (uri, protocols) {
            connectionCount++;
            return mockWebSocket = MockWebSocket.connect();
          },
          testInactivityTimeout: Duration(seconds: 1),
        ),
        cache: GraphQLCache(),
      );

      // Perform a query
      await gqlClient.query(QueryOptions(document: testQuery));
      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(connectionCount, 1);
      expect(initPayload['payload']['headers'], {});

      // Fake a login
      await nhost.auth.setSession(testSession);

      // Wait longer than the test inactivity timeout
      await Future.delayed(Duration(seconds: 2));

      // Check that a new connection has been established
      final nextInitPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(connectionCount, 2);
      expect(nextInitPayload['payload']['headers'], {
        'Authorization': 'Bearer $testJwt',
      });

      // Logout
      await nhost.auth.logout();

      // Wait longer than the test inactivity timeout
      await Future.delayed(Duration(seconds: 2));

      final lastInitPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(connectionCount, 3);
      expect(lastInitPayload['payload']['headers'], {});
    }));
  });
}
