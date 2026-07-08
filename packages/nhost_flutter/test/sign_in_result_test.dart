import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nhost_flutter/nhost_flutter.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

import 'helpers/fake_auth_client.dart';

// Minimal stub that lets each test control what signInEmailPassword returns.
class _SignInStub extends FakeAuthClient {
  _SignInStub() : super(AuthenticationState.signedOut);

  late AuthResponse Function() response;

  @override
  Future<AuthResponse> signInEmailPassword({
    required String email,
    required String password,
  }) async =>
      response();
}

// http.BaseRequest is abstract; extend with the minimum required.
class _BaseRequestStub extends http.BaseRequest {
  _BaseRequestStub(super.method, super.url);

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(const Stream.empty());
  }
}

class _FakeRequest extends _BaseRequestStub {
  _FakeRequest()
      : super('POST', Uri.parse('https://auth.example.com/signin/email-password'));
}

class _FakeResponse extends http.Response {
  _FakeResponse(int statusCode) : super('', statusCode);
}

void main() {
  group('NhostAuthClientSignInX.signIn', () {
    late _SignInStub client;

    setUp(() => client = _SignInStub());

    test('returns SignInSuccess when session is present', () async {
      final session = makeSession();
      client.response = () => AuthResponse(session: session);

      final result = await client.signIn(email: 'a@b.com', password: 'pass');

      expect(result, isA<SignInSuccess>());
      final success = result as SignInSuccess;
      expect(success.session, same(session));
      expect(success.user.email, 'test@example.com');
    });

    test('returns SignInNeedsMfa when mfa ticket is present', () async {
      client.response = () => AuthResponse(
            mfa: MultiFactorAuthenticationInfo(ticket: 'mfa-ticket-123'),
          );

      final result = await client.signIn(email: 'a@b.com', password: 'pass');

      expect(result, isA<SignInNeedsMfa>());
      expect((result as SignInNeedsMfa).ticket, 'mfa-ticket-123');
    });

    test('returns SignInNeedsEmailVerification when session and mfa are null', () async {
      client.response = () => AuthResponse();

      final result = await client.signIn(email: 'a@b.com', password: 'pass');

      expect(result, isA<SignInNeedsEmailVerification>());
    });

    test('propagates ApiException on sign-in failure', () {
      client.response = () => throw ApiException(
            Uri.parse('https://auth.example.com/signin/email-password'),
            {'message': 'Invalid email or password', 'status': 401},
            _FakeRequest(),
            _FakeResponse(401),
          );

      expect(
        () => client.signIn(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );
    });

    test('exhaustive switch covers all cases', () async {
      client.response = () => AuthResponse(session: makeSession());

      final result = await client.signIn(email: 'a@b.com', password: 'pass');

      final label = switch (result) {
        SignInSuccess() => 'success',
        SignInNeedsMfa() => 'mfa',
        SignInNeedsEmailVerification() => 'verify',
      };
      expect(label, 'success');
    });
  });
}
