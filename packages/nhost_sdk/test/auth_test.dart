import 'dart:convert';
import 'dart:io';

import 'package:otp/otp.dart';
import 'package:fake_async/fake_async.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:nock/nock.dart';
import 'package:test/test.dart';

import 'admin_gql.dart';
import 'setup.dart';
import 'test_helpers.dart';

const testEmail = 'user-1@nhost.io';
const testPassword = 'password-1';

void main() async {
  final unrecordedGqlAdmin = GqlAdminTestHelper(apiUrl: apiUrl, gqlUrl: gqlUrl);

  // This admin client has its traffic recorded for playback
  GqlAdminTestHelper gqlAdmin;
  Auth auth;

  setUpAll(() => initializeHttpFixturesForSuite('auth'));

  setUp(() async {
    // Clear out any data from the previous test
    await unrecordedGqlAdmin.clearUsers();

    // Get a recording/playback HTTP client from Betamax
    final httpClient = await setUpApiTest();

    // Create the service objects that we're going to be using to test
    gqlAdmin = GqlAdminTestHelper(
        apiUrl: apiUrl, gqlUrl: gqlUrl, httpClientOverride: httpClient);
    auth = createApiTestClient(httpClient).auth;
  });

  group('register', () {
    test('should succeed', () async {
      expect(
        auth.register(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should succeed with multiple unique users', () async {
      expect(
        auth.register(email: testEmail, password: testPassword),
        completes,
      );
      expect(
        auth.register(email: 'user-2@nhost.io', password: 'password-2'),
        completes,
      );
    });

    test('should not be able to register same user twice', () async {
      await auth.register(email: testEmail, password: testPassword);

      expect(
        auth.register(email: testEmail, password: testPassword),
        throwsA(anything),
      );
    });

    test('should not be able to register user with invalid email', () async {
      expect(
        auth.register(email: 'invalid-email.com', password: 'password'),
        throwsA(anything),
      );
    });

    test('should not be able to register without a password', () async {
      expect(
        auth.register(email: 'invalid-email.com', password: ''),
        throwsA(anything),
      );
    });

    test('should not be able to register without an email', () async {
      expect(
        auth.register(email: '', password: 'password'),
        throwsA(anything),
      );
    });

    test('should not be able to register without an email and password', () {
      expect(
        auth.register(email: '', password: ''),
        throwsA(anything),
      );
    });

    test('should not be able to register with a short password', () async {
      expect(
        auth.register(email: testEmail, password: 'a'),
        throwsA(anything),
      );
    });

    test('should be able to retrieve JSON Web Token', () async {
      await auth.register(email: testEmail, password: testPassword);
      expect(auth.jwt, isA<String>());
    });

    test('should be able to get user id as JWT claim', () async {
      await auth.register(email: testEmail, password: testPassword);
      expect(auth.getClaim('x-hasura-user-id'), isA<String>());
    });

    test('should be authenticated', () async {
      await auth.register(email: testEmail, password: testPassword);
      expect(auth.isAuthenticated, true);
    });
  });

  group('login', () {
    // Each tests registers a basic user, and leaves auth in a logged out state
    setUp(() async {
      await registerTestUser(auth);
      assert(!auth.isAuthenticated);
    });

    test('should be able to login with the correct password', () async {
      expect(
        auth.login(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should be able to logout and login', () async {
      await expectLater(
        auth.login(email: testEmail, password: testPassword),
        completes,
      );
      await auth.logout();
      expect(
        auth.login(email: testEmail, password: testPassword),
        completes,
      );
    });

    test('should not be able to login with wrong password', () async {
      expect(
        auth.login(email: testEmail, password: 'wrong-password-1'),
        throwsA(anything),
      );
    });

    test('should be authenticated', () async {
      await auth.login(email: testEmail, password: testPassword);
      expect(auth.isAuthenticated, true);
    });

    test('should be able to retreive JWT Token', () async {
      await auth.login(email: testEmail, password: testPassword);
      expect(auth.jwt, isA<String>());
    });

    test('should be able to get user id as JWT claim', () async {
      await auth.login(email: testEmail, password: testPassword);
      expect(auth.getClaim('x-hasura-user-id'), isA<String>());
    });
  });

  group('logout', () {
    // All logout tests log a user in first
    setUp(() async {
      await registerAndLoginBasicUser(auth);
    });

    test('should be able to logout', () async {
      expect(auth.logout(), completes);
    });

    test('should be able to logout twice', () async {
      await expectLater(auth.logout(), completes);
      await expectLater(auth.logout(), completes);
    });

    test('a logged out user should not be authenticated', () async {
      await auth.logout();
      expect(auth.isAuthenticated, false);
    });

    test('should not be able to retreive JWT token after logout', () async {
      await auth.logout();
      expect(auth.jwt, isNull);
    });

    test('should not be able to retreive JWT claim after logout', () async {
      await auth.logout();
      expect(auth.getClaim('x-hasura-user-id'), isNull);
    });
  });

  group('authentication state callbacks', () {
    bool authStateVar;
    UnsubscribeDelegate unsubscribe;

    setUp(() {
      authStateVar = false;
      unsubscribe = auth.addAuthStateChangedCallback(({authenticated}) {
        authStateVar = authenticated;
      });
    });

    test('should be called on login', () async {
      await registerTestUser(auth);
      await auth.login(email: testEmail, password: testPassword);
      expect(authStateVar, true);
    });

    test('should be called on logout', () async {
      await registerTestUser(auth);
      await auth.logout();
      expect(authStateVar, false);
    });

    test('should not be called once unsubscribed', () async {
      await registerTestUser(auth);
      unsubscribe();
      await auth.login(email: testEmail, password: testPassword);
      expect(authStateVar, false);
    });
  });

  group('authentication tokens refreshes', () {
    final mockFirstSession = Session(
      jwtToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNjE1NjA1NDI4fQ.'
          'AO75CQWd1NY8dwEdHm5cM-8TTq3ypFI8zFq12cfPOm8',
      jwtExpiresIn: Duration(hours: 6),
      refreshToken: 'abcd',
      user: User(id: 'xxxxxxxx', email: testEmail),
    );

    final mockNextSession = mockFirstSession.copyWith(
      jwtToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNjE1NjA2MDI4fQ.'
          '1mGtlyZdk3r7htZnHLyIfYQd5Gq0Oxp3VOAtqRFK8NA',
      refreshToken: 'efgh',
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
      Duration elapseTimeBy,
    }) {
      final interceptor = nock('$apiUrl/auth').get('/token/refresh')
        ..query({
          'refresh_token': mockFirstSession.refreshToken,
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
        async.elapse(elapseTimeBy);
        async.flushMicrotasks();
      });

      return interceptor;
    }

    test('should occur after a server-determined interval', () {
      final nhostClient = NhostClient(
        baseUrl: apiUrl,
      );
      final tokenEndpointRefreshMock = runTokenRefreshSequence(
        nhostClient,
        elapseTimeBy: mockFirstSession.jwtExpiresIn,
      );

      expect(tokenEndpointRefreshMock.isDone, isTrue);
      expect(nhostClient.auth.jwt, mockNextSession.jwtToken);
    }, tags: noHttpFixturesTag);

    test('should occur after a user-provided interval, if specified', () {
      final testRefreshInterval = Duration(minutes: 10);

      final nhostClient = NhostClient(
        baseUrl: apiUrl,
        tokenRefreshInterval: testRefreshInterval,
      );
      final tokenEndpointRefreshMock = runTokenRefreshSequence(
        nhostClient,
        elapseTimeBy: testRefreshInterval,
      );

      expect(tokenEndpointRefreshMock.isDone, isTrue);
      expect(nhostClient.auth.jwt, mockNextSession.jwtToken);
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

    //   // Now logout, and try with the new email
    //   await auth.logout();
    //   expect(
    //     auth.login(email: newEmail, password: testPassword),
    //     completes,
    //   );
    // });

    test('should be able to change email via request and confirmation',
        () async {
      const expectedNewEmail = 'new-user-1@nhost.io';

      await auth.requestEmailChange(newEmail: expectedNewEmail);
      await auth.confirmEmailChange(
        ticket: await gqlAdmin.getChangeTicketForUser(auth.currentUser.id),
      );
      await auth.logout();

      await expectLater(
        auth.login(
          email: expectedNewEmail,
          password: 'password-1',
        ),
        completes,
      );
      expect(auth.isAuthenticated, true);
    });
  });

  group('password change', () {
    setUp(() async {
      await registerAndLoginBasicUser(auth);
    });

    test('should be able to change password directly', () async {
      const newPassword = 'password-1-new';
      await expectLater(
        auth.changePassword(
          oldPassword: testPassword,
          newPassword: newPassword,
        ),
        completes,
      );

      // Now logout, and try with the new pass
      await auth.logout();
      expect(
        auth.login(email: testEmail, password: newPassword),
        completes,
      );
    });

    test('should not change passwords if old password is incorrect', () async {
      expect(
        auth.changePassword(
          oldPassword: 'wrong-old-password-1',
          newPassword: 'new-password-1',
        ),
        throwsA(anything),
      );
    });

    test('should be able to change password via request and confirmation',
        () async {
      await auth.requestPasswordChange(email: auth.currentUser.email);
      await auth.confirmPasswordChange(
        newPassword: 'requested-new-password-1',
        ticket: await gqlAdmin.getChangeTicketForUser(auth.currentUser.id),
      );
      await auth.logout();

      expect(
        auth.login(
          email: testEmail,
          password: 'requested-new-password-1',
        ),
        completes,
      );
    });
  });

  group('multi-factor authentication', () {
    test('can be enabled on a user', () async {
      await registerAndLoginBasicUser(auth);

      // Ask the backend to generate MFA configuration, and from that, generate
      // a time-based OTP.
      final mfaConfiguration = await auth.generateMfa();
      final totp = OTP.generateTOTPCodeString(
          mfaConfiguration.otpSecret, DateTime.now().millisecondsSinceEpoch);

      expect(
        auth.enableMfa(totp),
        completes,
      );
    });

    test('should require TOTP for login once enabled', () async {
      final otpSecret = await registerMfaUser(auth);

      final firstFactorAuthResult =
          await auth.login(email: testEmail, password: testPassword);
      expect(firstFactorAuthResult.user, isNull);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.jwt, isNull);

      final secondFactorAuthResult = await auth.completeMfaLogin(
        code: totpFromSecret(otpSecret),
        ticket: firstFactorAuthResult.mfa.ticket,
      );
      expect(secondFactorAuthResult.user, isNotNull);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.jwt, isNotNull);
    });

    test('can be disabled', () async {
      final otpSecret = await registerMfaUser(auth, logout: false);

      expect(
        auth.disableMfa(totpFromSecret(otpSecret)),
        completes,
      );
    });
  });
}
