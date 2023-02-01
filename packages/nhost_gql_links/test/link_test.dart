import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:gql/language.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:nhost_gql_links/nhost_gql_links.dart';
import 'package:nhost_dart/nhost_dart.dart';
import 'package:nock/nock.dart';
import 'package:test/test.dart';

import 'mock_web_socket.dart';

const subdomain = 'test';
const region = 'eu-central-1';
const baseUrl = 'https://$subdomain.graphql.$region.nhost.run';
const gqlEndpointPath = '/v1';
const gqlEndpoint = '$baseUrl/v1';

final testQuery = parseString('query todos { id }');
final testSubscription = parseString('subscription todos { id }');
const testJwt = 'eyJhbGciOiJIUzI1NiJ9.'
    'eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLXVzZXItaWQiOiJmMmZhMWJjNS03YmI5LTRjYjgtOTg5Ny0yZWQxMjhiN2I1YjkiLCJ4LWhhc3VyYS1hbGxvd2VkLXJvbGVzIjpbInVzZXIiXSwieC1oYXN1cmEtZGVmYXVsdC1yb2xlIjoidXNlciJ9LCJpYXQiOjE2MTU5OTk3NDksImV4cCI6MTYxNjAwMDY0OX0.'
    '1gDRrG8OYtjAzgSYWd2RzdYRKhaFG_3HBkpfVbSzk_w';
const testJwtAlt = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.'
    'eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLXVzZXItaWQiOiJmMmZhMWJjNS1kZGRkZGQtNGNiOC05ODk3LTJlZDEyOGI3YjViOSIsIngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsidXNlciJdLCJ4LWhhc3VyYS1kZWZhdWx0LXJvbGUiOiJ1c2VyIn0sImlhdCI6MTYxNTk5OTc0OSwiZXhwIjoxNjIxMjQ5Njk0LCJqdGkiOiI3YjRjODYxNC1hZTk0LTQ0Y2QtYTdmZS0yMmMwNDlkZDdmNzQifQ.'
    'MyXIMqgjw9k4YE_64ea7Z6WDdHJ0v1H6qkjdxSFi2xk';
final testSession = Session(
  accessToken: testJwt,
  accessTokenExpiresIn: Duration(days: 1),
  refreshToken: 'abcd',
);

const emptyResponse = '{"data": {}}';

void main() {
  late NhostClient nhost;
  setUp(() {
    nhost = NhostClient(
      subdomain: Subdomain(
        subdomain: subdomain,
        region: region,
      ),
    );
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
        ..reply(200, emptyResponse);

      // Fake authentication with Nhost
      await nhost.auth.setSession(testSession);

      // Perform a query
      final gqlClient = combinedLinkForNhost(nhost);

      await gqlClient
          .request(Request(operation: Operation(document: testQuery)))
          .first;

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
        ..reply(200, emptyResponse);

      // Perform a query
      final gqlClient = combinedLinkForNhost(nhost);
      await gqlClient
          .request(Request(operation: Operation(document: testQuery)))
          .first;

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
        ..reply(200, emptyResponse);

      // Perform a query
      final gqlClient = combinedLinkForNhost(
        nhost,
        defaultHeaders: expectedHeaders,
      );
      await gqlClient
          .request(Request(operation: Operation(document: testQuery)))
          .first;

      // Check if the interceptor matched
      expect(interceptor.isDone, true);
    });
  });

  group('web socket links', () {
    late MockWebSocket mockWebSocket;

    setUp(() {
      mockWebSocket = MockWebSocket.connect();
    });

    tearDown(() {
      mockWebSocket.tearDown();
    });

    test('authenticated clients send auth headers', () async {
      final expectedHeaders = {
        'Authorization': 'Bearer $testJwt',
      };

      // Fake authentication with Nhost
      await nhost.auth.setSession(testSession);

      // Perform a query
      final gqlClient = webSocketLinkForNhost(
        gqlEndpoint,
        nhost.auth,
        testChannelGenerator: () => mockWebSocket,
      );
      await gqlClient
          .request(Request(operation: Operation(document: testSubscription)))
          .first;

      // Ensure headers were sent
      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(initPayload['payload']['headers'], equals(expectedHeaders));
    });

    test('unauthenticated clients do not send auth headers', () async {
      final expectedHeaders = {};

      // Perform a query
      final gqlClient = webSocketLinkForNhost(
        gqlEndpoint,
        nhost.auth,
        testChannelGenerator: () => mockWebSocket,
      );
      await gqlClient
          .request(Request(operation: Operation(document: testSubscription)))
          .first;

      // Ensure no headers were sent
      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(initPayload['payload']['headers'], equals(expectedHeaders));
    });

    test('default headers are provided in request', () async {
      final expectedHeaders = {
        'x-hasura-role': 'superuser',
      };

      // Perform a query
      final gqlClient = webSocketLinkForNhost(
        gqlEndpoint,
        nhost.auth,
        defaultHeaders: expectedHeaders,
        testChannelGenerator: () => mockWebSocket,
      );
      await gqlClient
          .request(Request(operation: Operation(document: testSubscription)))
          .first;

      // Ensure headers were sent
      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(initPayload['payload']['headers'], equals(expectedHeaders));
    });

    test('reconnects on auth changes', () async {
      var connectionCount = 0;
      late MockWebSocket mockWebSocket;
      final nhostLink = webSocketLinkForNhost(
        gqlEndpoint,
        nhost.auth,
        testChannelGenerator: () {
          connectionCount++;
          return mockWebSocket = MockWebSocket.connect();
        },
        testInactivityTimeout: null,
        testReconnectTimeout: Duration(milliseconds: 16),
      );

      // Perform a query
      nhostLink
          .request(Request(operation: Operation(document: testSubscription)))
          .listen((event) {});
      await Future.delayed(Duration(seconds: 2));

      final initPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(connectionCount, 1);
      expect(initPayload['payload']['headers'], {});

      // Fake a sign in
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
      await nhost.auth.signOut();

      // Wait longer than the test inactivity timeout
      await Future.delayed(Duration(seconds: 2));

      final lastInitPayload = jsonDecode(mockWebSocket.payloads.first);
      expect(connectionCount, 3);
      expect(lastInitPayload['payload']['headers'], {});
    });

    test('recreates subscriptions on auth reconnects', () {
      fakeAsync((async) {
        // Login
        nhost.auth.setSession(testSession);
        async.flushMicrotasks();

        late MockWebSocket mockWebSocket;
        final nhostLink = webSocketLinkForNhost(
          gqlEndpoint,
          nhost.auth,
          testChannelGenerator: () => mockWebSocket = MockWebSocket.connect(),
          testInactivityTimeout: null,
          testReconnectTimeout: Duration(milliseconds: 0),
        );

        // Perform a subscription query
        nhostLink
            .request(Request(operation: Operation(document: testSubscription)))
            .listen((event) {});
        async.flushMicrotasks();

        // Ensure that we see a subscription request as the most recent message
        final initAuthPayload = jsonDecode(mockWebSocket.payloads.first);
        final initSubscribePayload = jsonDecode(mockWebSocket.payloads.last);
        expect(initSubscribePayload['type'], 'start');

        // Change the auth token, which triggers a reconnection on the socket
        nhost.auth.setSession(Session(
          accessToken: testJwtAlt,
          accessTokenExpiresIn: Duration(days: 1),
          refreshToken: 'abcd',
        ));
        // 1 second is arbitrary. This call flushes microtasks, and invokes
        // the reconnection timer's callback
        async.elapse(Duration(seconds: 1));

        // Check that we are leading with a new auth request (indicating a new
        // session), and that we have a subscription start message following it
        // (indicating that the subscription request is new, because payloads are
        // time ordered)
        final nextAuthPayload = jsonDecode(mockWebSocket.payloads.first);
        final nextSubscribePayload = jsonDecode(mockWebSocket.payloads.last);
        expect(nextAuthPayload['payload']['headers']['Authorization'],
            isNot(initAuthPayload['payload']['headers']['Authorization']));
        expect(nextSubscribePayload['type'], 'start');
      });
    });

    test('uses a suitable close code when reconnecting on auth changes', () {
      fakeAsync((async) {
        // Login
        nhost.auth.setSession(testSession);
        async.flushMicrotasks();

        late MockWebSocket mockWebSocket;
        final nhostLink = webSocketLinkForNhost(
          gqlEndpoint,
          nhost.auth,
          testChannelGenerator: () => mockWebSocket = MockWebSocket.connect(),
          testInactivityTimeout: null,
          // Set a very high reconnect, so we can catch the close code before
          // the sink gets overwritten
          testReconnectTimeout: Duration(days: 1),
        );

        // Perform a subscription query
        nhostLink
            .request(Request(operation: Operation(document: testSubscription)))
            .listen((event) {});
        async.flushMicrotasks();

        // Change the auth token, which triggers a reconnection on the socket
        nhost.auth.setSession(Session(
          accessToken: testJwtAlt,
          accessTokenExpiresIn: Duration(days: 1),
          refreshToken: 'abcd',
        ));
        async.elapse(Duration(seconds: 1));

        expect(mockWebSocket.sink.lastCloseCode, webSocketNormalCloseCode);
      });
    });
  });
}
