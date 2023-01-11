import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_sdk/src/foundation/uri.dart';
import 'package:nock/nock.dart';
import 'package:test/test.dart';

import 'admin_gql.dart';
import 'setup.dart';
import 'test_helpers.dart';

const testEmail = 'user-1@nhost.io';
const testPassword = 'password-1';

const invalidRefreshToken = '10b27fd6-a606-42f4-9063-d6bd9d7866c8';

void main() async {
  final gqlAdmin = GqlAdminTestHelper(
    subdomain: subdomain,
    region: region,
    gqlUrl: gqlUrl,
  );

  late NhostClient nhost;
  late AuthClient auth;
  late AuthStore authStore;

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
    nhost = createApiTestClient(
      httpClient,
      authStore: authStore = InMemoryAuthStore(),
    );
    auth = nhost.auth;
  });

  tearDown(() {
    // nhost.close();
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
      expect(auth.accessToken, isA<String>());
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
    late String refreshToken;
    // Each tests registers a basic user, and leaves auth in a logged out state
    setUp(() async {
      final res = await registerAndSignInBasicUser(auth);
      refreshToken = res.session!.refreshToken!;
      // Don't log out, so we can keep a valid refresh token
      await auth.clearSession();
      assert(auth.authenticationState == AuthenticationState.signedOut);
    });

    test('should be able to signIn with the correct password', () async {
      expect(
        auth.signInEmailPassword(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should be able to signOut and signIn', () async {
      await expectLater(
        auth.signInEmailPassword(email: testEmail, password: testPassword),
        completes,
      );
      await auth.signOut();
      expect(
        auth.signInEmailPassword(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should not be able to signIn with wrong password', () async {
      expect(
        auth.signInEmailPassword(
            email: testEmail, password: 'wrong-password-1'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(HttpStatus.unauthorized),
        )),
      );
    });

    test('should be authenticated', () async {
      await auth.signInEmailPassword(email: testEmail, password: testPassword);
      expect(auth.authenticationState, AuthenticationState.signedIn);
    });

    test('should be able to retreive JWT Token', () async {
      await auth.signInEmailPassword(email: testEmail, password: testPassword);
      expect(auth.accessToken, isA<String>());
    });

    test('should be able to get user id as JWT claim', () async {
      await auth.signInEmailPassword(email: testEmail, password: testPassword);
      expect(auth.getClaim('x-hasura-user-id'), isA<String>());
    });

    group('passwordless', () {
      group('email passwordless', () {
        test('should be able to sign in', () async {
          // Can't be tested meaningfully at the moment
        });
      });

      group('SMS passwordless', () {
        test('should be able to sign in with the OTP', () async {
          // Can't be tested meaningfully at the moment
        });
      });
    });

    group('with stored credentials', () {
      test('sets state when successful', () async {
        await authStore.setString(refreshTokenClientStorageKey, refreshToken);
        expect(auth.currentUser, isNull);
        await auth.signInWithStoredCredentials();

        expect(auth.authenticationState, AuthenticationState.signedIn);
        expect(auth.currentUser, isNotNull);
      });

      test('throws when the stored token is invalid', () async {
        await authStore.setString(
          refreshTokenClientStorageKey,
          invalidRefreshToken,
        );
        expect(
          auth.signInWithStoredCredentials(),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          )),
        );
      });

      test('throws when no refresh token exists in AuthStore', () async {
        expect(
          () => auth.signInWithStoredCredentials(),
          throwsA(isA<NhostException>()),
        );
      });
    });

    group('with refresh token', () {
      test('sets state when successful', () async {
        await auth.signInWithRefreshToken(refreshToken);

        expect(auth.authenticationState, AuthenticationState.signedIn);
        expect(auth.currentUser, isNotNull);
      });

      test('throws when the token is invalid', () async {
        expect(
          auth.signInWithRefreshToken(invalidRefreshToken),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            HttpStatus.unauthorized,
          )),
        );
      });
    });
  });

  group('signOut', () {
    // All signOut tests log a user in first
    setUp(() async {
      await registerAndSignInBasicUser(auth);
      assert(auth.currentUser != null);
    });

    test('should be able to signOut', () async {
      expect(auth.signOut(), completes);
    });

    test('a signed out client should not be authenticated', () async {
      await auth.signOut();
      expect(auth.authenticationState, AuthenticationState.signedOut);
    });

    test('a signed out client should not have a user', () async {
      await auth.signOut();
      expect(auth.currentUser, isNull);
    });

    test('should not be able to retreive JWT token after signOut', () async {
      await auth.signOut();
      expect(auth.accessToken, isNull);
    });

    test('should not be able to retreive JWT claim after signOut', () async {
      await auth.signOut();
      expect(auth.getClaim('x-hasura-user-id'), isNull);
    });
  });

  group('sending verification email', () {
    test('should fail when the user does not exist', () {
      expect(
        auth.sendVerificationEmail(email: 'foo@bar.com'),
        throwsA(anything),
      );
    });

    test('succeeds if the user exists', () async {
      await registerTestUser(auth);
      expect(
        auth.sendVerificationEmail(email: defaultTestEmail),
        completes,
      );
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

    test('should be called on sign in', () async {
      await registerTestUser(auth);
      await auth.signInEmailPassword(email: testEmail, password: testPassword);
      expect(authStateVar, AuthenticationState.signedIn);
    });

    test('should be called on sign out', () async {
      await registerTestUser(auth);
      await auth.signOut();
      expect(authStateVar, AuthenticationState.signedOut);
    });

    test('should not be called once unsubscribed', () async {
      await registerTestUser(auth);
      unsubscribe();
      await auth.signInEmailPassword(email: testEmail, password: testPassword);
      expect(authStateVar, AuthenticationState.signedOut);
    });
  });

  group('session refresh failure callbacks', () {
    test('are called when refresh tokens are invalid', () async {
      final _callbackCompleter = Completer();
      auth.addSessionRefreshFailedCallback((error, stackTrace) {
        _callbackCompleter.completeError(error, stackTrace);
      });

      final unauthorizedMatcher = throwsA(isA<ApiException>().having(
        (e) => e.statusCode,
        'statusCode',
        HttpStatus.unauthorized,
      ));

      expect(
        _callbackCompleter.future,
        unauthorizedMatcher,
      );
      expect(
        auth.signInWithRefreshToken(invalidRefreshToken),
        unauthorizedMatcher,
      );
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
      final interceptor = nock(
        createNhostServiceEndpoint(
          subdomain: subdomain,
          region: region,
          service: 'auth',
        ),
      ).post(
        '/token',
        anything,
      )
        ..body = jsonEncode(
          {
            'refreshToken': mockFirstSession.refreshToken,
          },
        )
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
        subdomain: subdomain,
        region: region,
      );
      final tokenEndpointRefreshMock = runTokenRefreshSequence(
        nhostClient,
        elapseTimeBy: mockFirstSession.accessTokenExpiresIn,
      );

      expect(tokenEndpointRefreshMock.isDone, isTrue);
      expect(nhostClient.auth.accessToken, mockNextSession.accessToken);
    }, tags: noHttpFixturesTag); // Don't record fixtures

    test('should occur after a user-provided interval, if specified', () {
      final testRefreshInterval = Duration(minutes: 10);

      final nhostClient = NhostClient(
        subdomain: subdomain,
        region: region,
        tokenRefreshInterval: testRefreshInterval,
      );
      final tokenEndpointRefreshMock = runTokenRefreshSequence(
        nhostClient,
        elapseTimeBy: testRefreshInterval,
      );

      expect(tokenEndpointRefreshMock.isDone, isTrue);
      expect(nhostClient.auth.accessToken, mockNextSession.accessToken);
    }, tags: noHttpFixturesTag); // Don't record fixtures
  });

  group('email change', () {
    setUp(() async {
      await registerAndSignInBasicUser(auth);
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
      await registerAndSignInBasicUser(auth);
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
        auth.signInEmailPassword(email: testEmail, password: newPassword),
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
      await registerAndSignInBasicUser(auth);

      // Ask the backend to generate MFA configuration, and from that, generate
      // a time-based OTP.
      final mfaConfiguration = await auth.generateMfa();
      final totp = totpFromSecret(mfaConfiguration.totpSecret);

      expect(
        auth.enableMfa(totp),
        completes,
      );
    });

    test('should require TOTP for sign in once enabled', () async {
      final otpSecret = await registerMfaUser(auth);

      final firstFactorAuthResult = await auth.signInEmailPassword(
          email: testEmail, password: testPassword);
      expect(firstFactorAuthResult.user, isNull);
      expect(auth.authenticationState, AuthenticationState.signedOut);
      expect(auth.accessToken, isNull);

      final secondFactorAuthResult = await auth.completeMfaSignIn(
        otp: totpFromSecret(otpSecret),
        ticket: firstFactorAuthResult.mfa!.ticket,
      );
      expect(secondFactorAuthResult.user, isNotNull);
      expect(auth.authenticationState, AuthenticationState.signedIn);
      expect(auth.accessToken, isNotNull);
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
