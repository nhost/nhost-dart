import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nock/nock.dart';
import 'package:test/test.dart';

import 'admin_gql.dart';
import 'setup.dart';
import 'test_helpers.dart';

const testEmail = 'user-1@nhost.io';
const testPassword = 'password-1';

void main() async {
  final gqlAdmin =
      GqlAdminTestHelper(apiUrl: backendUrl, gqlUrl: gqlUrl);

  // This admin client has its traffic recorded for playback
  late NhostClient nhost;
  late AuthClient auth;

  setUpAll(() {
    initLogging();
    initializeHttpFixturesForSuite('auth');
  });

  setUp(() async {
    // Clear out any data from the previous test
    await gqlAdmin.clearUsers();

    // Get a recording/playback HTTP client from Betamax
    final httpClient = await setUpApiTest();

    // Create the service objects that we're going to be using to test
    nhost = createApiTestClient(httpClient);
    auth = nhost.auth;
  });

  tearDown(() {
    nhost.close();
  });

  group('sign up', () {
    test('should succeed', () async {
      expect(
        auth.signUp(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should succeed with multiple unique users', () async {
      expect(
        auth.signUp(email: testEmail, password: testPassword),
        completes,
      );
      expect(
        auth.signUp(email: 'user-2@nhost.io', password: 'password-2'),
        completes,
      );
    });

    test('should not be able to sign up same user twice', () async {
      await auth.signUp(email: testEmail, password: testPassword);

      expect(
        auth.signUp(email: testEmail, password: testPassword),
        throwsA(anything),
      );
    });

    test('should not be able to sign up user with invalid email', () async {
      expect(
        auth.signUp(email: 'invalid-email.com', password: 'password'),
        throwsA(anything),
      );
    });

    test('should not be able to sign up without a password', () async {
      expect(
        auth.signUp(email: 'invalid-email.com', password: ''),
        throwsA(anything),
      );
    });

    test('should not be able to sign up without an email', () async {
      expect(
        auth.signUp(email: '', password: 'password'),
        throwsA(anything),
      );
    });

    test('should not be able to sign up without an email and password', () {
      expect(
        auth.signUp(email: '', password: ''),
        throwsA(anything),
      );
    });

    test('should not be able to sign up with a short password', () async {
      expect(
        auth.signUp(email: testEmail, password: 'a'),
        throwsA(anything),
      );
    });

    test('should be able to retrieve JSON Web Token', () async {
      await auth.signUp(email: testEmail, password: testPassword);
      expect(auth.jwt, isA<String>());
    });

    test('should be able to get user id as JWT claim', () async {
      await auth.signUp(email: testEmail, password: testPassword);
      expect(auth.getClaim('x-hasura-user-id'), isA<String>());
    });

    test('should be authenticated', () async {
      await auth.signUp(email: testEmail, password: testPassword);
      expect(auth.authenticationState, AuthenticationState.signedIn);
    });
  });

  group('signIn', () {
    // Each tests registers a basic user, and leaves auth in a logged out state
    setUp(() async {
      await registerTestUser(auth);
      assert(auth.authenticationState == AuthenticationState.signedOut);
    });

    test('should be able to signIn with the correct password', () async {
      expect(
        auth.signIn(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should be able to signOut and signIn', () async {
      await expectLater(
        auth.signIn(email: testEmail, password: testPassword),
        completes,
      );
      await auth.signOut();
      expect(
        auth.signIn(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should not be able to signIn with wrong password', () async {
      expect(
        auth.signIn(email: testEmail, password: 'wrong-password-1'),
        throwsA(anything),
      );
    });

    test('should be authenticated', () async {
      await auth.signIn(email: testEmail, password: testPassword);
      expect(auth.authenticationState, AuthenticationState.signedIn);
    });

    test('should be able to retreive JWT Token', () async {
      await auth.signIn(email: testEmail, password: testPassword);
      expect(auth.jwt, isA<String>());
    });

    test('should be able to get user id as JWT claim', () async {
      await auth.signIn(email: testEmail, password: testPassword);
      expect(auth.getClaim('x-hasura-user-id'), isA<String>());
    });
  });

  group('signOut', () {
    // All signOut tests log a user in first
    setUp(() async {
      await registerAndLoginBasicUser(auth);
    });

    test('should be able to signOut', () async {
      expect(auth.signOut(), completes);
    });

    test('a signed out user should not be authenticated', () async {
      await auth.signOut();
      expect(auth.authenticationState, AuthenticationState.signedOut);
    });

    test('should not be able to retreive JWT token after signOut', () async {
      await auth.signOut();
      expect(auth.jwt, isNull);
    });

    test('should not be able to retreive JWT claim after signOut', () async {
      await auth.signOut();
      expect(auth.getClaim('x-hasura-user-id'), isNull);
    });
  });

  group('authentication state callbacks', () {
    AuthenticationState? authStateVar;
    late UnsubscribeDelegate unsubscribe;

    setUp(() {
      authStateVar = AuthenticationState.inProgress;
      unsubscribe = auth.addAuthStateChangedCallback((authState) {
        authStateVar = authState;
      });
    });

    test('should be called on login', () async {
      await registerTestUser(auth);
      await auth.signIn(email: testEmail, password: testPassword);
      expect(authStateVar, AuthenticationState.signedIn);
    });

    test('should be called on signOut', () async {
      await registerTestUser(auth);
      await auth.signOut();
      expect(authStateVar, AuthenticationState.signedOut);
    });

    test('should not be called once unsubscribed', () async {
      await registerTestUser(auth);
      unsubscribe();
      await auth.signIn(email: testEmail, password: testPassword);
      expect(authStateVar, AuthenticationState.signedOut);
    });
  });

  group('authentication tokens refreshes', () {
    final mockFirstSession = Session(
      accessToken:
          'eyJhbGciOiJIUzI1NiJ9.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsidXNlciIsIm1lIl0sIngtaGFzdXJhLWRlZmF1bHQtcm9sZSI6InVzZXIiLCJ4LWhhc3VyYS11c2VyLWlkIjoiNzEwYTgyNjMtNTgyNi00NTYzLWE4YTUtNGUyNzJkNDQxYWVkIiwieC1oYXN1cmEtdXNlci1pc0Fub255bW91cyI6ImZhbHNlIn0sInN1YiI6IjcxMGE4MjYzLTU4MjYtNDU2My1hOGE1LTRlMjcyZDQ0MWFlZCIsImlzcyI6Imhhc3VyYS1hdXRoIiwiaWF0IjoxNjQzMzQ3NzgwLCJleHAiOjE2NDMzNDg2ODB9.xzsBH0p34ynPwaHnNs97gVL5tdrcdFOrxosuqBra1iw',
      accessTokenExpiresIn: Duration(seconds: 900),
      refreshToken: 'abcd',
      user: createTestUser(id: 'xxxxxxxx', email: testEmail),
    );

    final mockNextSession = mockFirstSession.copyWith(
      accessToken:
          'eyJhbGciOiJIUzI1NiJ9.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsidXNlciIsIm1lIl0sIngtaGFzdXJhLWRlZmF1bHQtcm9sZSI6InVzZXIiLCJ4LWhhc3VyYS11c2VyLWlkIjoiNzEwYTgyNjMtNTgyNi00NTYzLWE4YTUtNGUyNzJkNDQxYWVkIiwieC1oYXN1cmEtdXNlci1pc0Fub255bW91cyI6ImZhbHNlIn0sInN1YiI6IjcxMGE4MjYzLTU4MjYtNDU2My1hOGE1LTRlMjcyZDQ0MWFlZCIsImlzcyI6Imhhc3VyYS1hdXRoIiwiaWF0IjoxNjQzMzQ4NjgwLCJleHAiOjE2NDMzNDk1ODB9.DVcIUUMVpA7Pgit8pyci6-HUYOCZzYI4YvrZGAbgxvM',
      refreshToken: 'efgh',
      user: createTestUser(id: 'xxxx', email: 'user-1@nhost.io'),
    );

    setUpAll(() {
      nock.init();
    });

    setUp(() {
      nock.cleanAll();
    });

    tearDownAll(() {
      HttpOverrides.global = null;
    });

    Interceptor runTokenRefreshSequence(
      NhostClient client, {
      Duration? elapseTimeBy,
    }) {
      final interceptor = nock('$backendUrl/v1/auth').post('/token', anything)
        ..body = jsonEncode({
          'refreshToken': mockFirstSession.refreshToken,
        })
        ..reply(
          200,
          jsonEncode(mockNextSession.toJson()),
          headers: {
            HttpHeaders.contentTypeHeader: ContentType.json.toString(),
          },
        );

      fakeAsync((async) {
        final auth = client.auth;

        // Inject a session directly into the Auth, to simulate the server's
        // auth response.
        auth.setSession(mockFirstSession);

        // Move time forward by the refresh interval
        async.elapse(elapseTimeBy!);
        async.flushMicrotasks();
      });

      return interceptor;
    }

    test('should occur after a server-determined interval', () {
      final nhostClient = NhostClient(
        backendUrl: backendUrl,
      );
      final tokenEndpointRefreshMock = runTokenRefreshSequence(
        nhostClient,
        elapseTimeBy: mockFirstSession.accessTokenExpiresIn,
      );

      expect(tokenEndpointRefreshMock.isDone, isTrue);
      expect(nhostClient.auth.jwt, mockNextSession.accessToken);
    }, tags: noHttpFixturesTag);

    test('should occur after a user-provided interval, if specified', () {
      final testRefreshInterval = Duration(minutes: 10);

      final nhostClient = NhostClient(
        backendUrl: backendUrl,
        tokenRefreshInterval: testRefreshInterval,
      );
      final tokenEndpointRefreshMock = runTokenRefreshSequence(
        nhostClient,
        elapseTimeBy: testRefreshInterval,
      );

      expect(tokenEndpointRefreshMock.isDone, isTrue);
      expect(nhostClient.auth.jwt, mockNextSession.accessToken);
    }, tags: noHttpFixturesTag);
  });

  group('email change', () {
    setUp(() async {
      await registerAndLoginBasicUser(auth);
    });

    // This should be tested, but requires a server configured with
    // EMAIL_VERIFICATION=false
    //
    // test('should be able to change email directly', () async {
    //   const newEmail = 'new-user-1@nhost.io';
    //   await expectLater(
    //     auth.changeEmail(newEmail),
    //     completes,
    //   );

    //   // Now signOut, and try with the new email
    //   await auth.signOut();
    //   expect(
    //     auth.login(email: newEmail, password: testPassword),
    //     completes,
    //   );
    // });

    //!
    // test('should be able to change email via request and confirmation',
    //     () async {
    //   const expectedNewEmail = 'new-user-1@nhost.io';

    //   await auth.requestEmailChange(newEmail: expectedNewEmail);
    //   await auth.confirmEmailChange(
    //     ticket: await gqlAdmin.getChangeTicketForUser(auth.currentUser!.id),
    //   );
    //   await auth.signOut();

    //   await expectLater(
    //     auth.signIn(
    //       email: expectedNewEmail,
    //       password: 'password-1',
    //     ),
    //     completes,
    //   );
    //   expect(auth.authenticationState, AuthenticationState.signedIn);
    // });
  });

  group('password change', () {
    setUp(() async {
      await registerAndLoginBasicUser(auth);
    });

    test('should be able to change password directly', () async {
      const newPassword = 'password-1-new';
      await expectLater(
        auth.changePassword(
          newPassword: newPassword,
        ),
        completes,
      );

      // Now signOut, and try with the new pass
      await auth.signOut();
      expect(
        auth.signIn(email: testEmail, password: newPassword),
        completes,
      );
    });

    //!
    // test('should be able to change password via request and confirmation',
    //     () async {
    //   await auth.resetPassword(email: auth.currentUser!.email!);
    //   await auth.confirmPasswordChange(
    //     newPassword: 'requested-new-password-1',
    //     ticket: await gqlAdmin.getChangeTicketForUser(auth.currentUser!.id),
    //   );
    //   await auth.signOut();

    //   expect(
    //     auth.signIn(
    //       email: testEmail,
    //       password: 'requested-new-password-1',
    //     ),
    //     completes,
    //   );
    // });
  });

  group('multi-factor authentication', () {
    test('can be enabled on a user', () async {
      await registerAndLoginBasicUser(auth);

      // Ask the backend to generate MFA configuration, and from that, generate
      // a time-based OTP.
      final mfaConfiguration = await auth.generateMfa();
      final totp = totpFromSecret(mfaConfiguration.totpSecret);

      expect(
        auth.enableMfa(totp),
        completes,
      );
    });

    test('should require TOTP for login once enabled', () async {
      final otpSecret = await registerMfaUser(auth);

      final firstFactorAuthResult =
          await auth.signIn(email: testEmail, password: testPassword);
      expect(firstFactorAuthResult.user, isNull);
      expect(auth.authenticationState, AuthenticationState.signedOut);
      expect(auth.jwt, isNull);

      final secondFactorAuthResult = await auth.completeMfaSignIn(
        otp: totpFromSecret(otpSecret),
        ticket: firstFactorAuthResult.mfa!.ticket,
      );
      expect(secondFactorAuthResult.user, isNotNull);
      expect(auth.authenticationState, AuthenticationState.signedIn);
      expect(auth.jwt, isNotNull);
    });

    test('can be disabled', () async {
      final otpSecret = await registerMfaUser(auth, signOut: false);

      expect(
        auth.disableMfa(totpFromSecret(otpSecret)),
        completes,
      );
    });
  });
}
