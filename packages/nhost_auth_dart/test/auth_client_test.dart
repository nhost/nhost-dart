import 'package:nhost_auth_dart/nhost_auth_dart.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:test/test.dart';

const _accessToken = 'eyJhbGciOiJIUzI1NiJ9.'
    'eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsidXNlciIsIm1lIl0sIngtaGFzdXJhLWRlZmF1bHQtcm9sZSI6InVzZXIiLCJ4LWhhc3VyYS11c2VyLWlkIjoiNzEwYTgyNjMtNTgyNi00NTYzLWE4YTUtNGUyNzJkNDQxYWVkIiwieC1oYXN1cmEtdXNlci1pc0Fub255bW91cyI6ImZhbHNlIn0sInN1YiI6IjcxMGE4MjYzLTU4MjYtNDU2My1hOGE1LTRlMjcyZDQ0MWFlZCIsImlzcyI6Imhhc3VyYS1hdXRoIiwiaWF0IjoxNjQzMzQ3NzgwLCJleHAiOjE2NDMzNDg2ODB9.'
    'xzsBH0p34ynPwaHnNs97gVL5tdrccFOrxosuqBra1iw';
const _refreshToken = 'refresh-token-should-not-be-logged';

void main() {
  group('NhostAuthClient', () {
    test('does not expose session tokens in string output', () async {
      final auth = NhostAuthClient(url: 'http://localhost');
      addTearDown(auth.close);

      await auth.setSession(
        Session(
          accessToken: _accessToken,
          accessTokenExpiresIn: Duration(seconds: 900),
          refreshToken: _refreshToken,
          user: User(
            id: '710a8263-5826-4563-a8a5-4e272d441aed',
            displayName: 'Test User',
            locale: 'en',
            createdAt: DateTime.utc(2024),
            isAnonymous: false,
            defaultRole: 'user',
            roles: const ['user'],
            emailVerified: true,
            phoneNumber: '',
            phoneNumberVerified: false,
            email: 'test@example.com',
          ),
        ),
      );

      final output = auth.toString();

      expect(output, isNot(contains(_accessToken)));
      expect(output, isNot(contains(_refreshToken)));
      expect(output, contains('accessToken: <redacted>'));
      expect(output, contains('refreshToken: <redacted>'));
      expect(output, contains('test@example.com'));
    });
  });
}
