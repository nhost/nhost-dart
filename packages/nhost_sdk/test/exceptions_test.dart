import 'package:http/http.dart' as http;
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:test/test.dart';

// Minimal BaseRequest subclass needed to construct ApiException.
class _FakeRequest extends http.BaseRequest {
  _FakeRequest() : super('POST', Uri.parse('https://auth.example.com/test'));

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(const Stream.empty());
  }
}

ApiException _makeException(int statusCode, dynamic body) => ApiException(
      Uri.parse('https://auth.example.com/test'),
      body,
      _FakeRequest(),
      http.Response('', statusCode),
    );

void main() {
  group('ApiException', () {
    group('errorCode / errorMessage', () {
      test('parses errorCode and errorMessage from a Nhost error body', () {
        final e = _makeException(400, {
          'error': 'invalid-request',
          'message': 'Password is too short',
          'status': 400,
        });

        expect(e.errorCode, 'invalid-request');
        expect(e.errorMessage, 'Password is too short');
      });

      test('returns null when body is not a Map', () {
        final e = _makeException(500, 'Internal Server Error');

        expect(e.errorCode, isNull);
        expect(e.errorMessage, isNull);
      });

      test('returns null when body is null', () {
        final e = _makeException(500, null);

        expect(e.errorCode, isNull);
        expect(e.errorMessage, isNull);
      });
    });

    group('convenience booleans', () {
      test('isUnauthorized is true for 401', () {
        expect(_makeException(401, null).isUnauthorized, isTrue);
        expect(_makeException(403, null).isUnauthorized, isFalse);
      });

      test('isForbidden is true for 403', () {
        expect(_makeException(403, null).isForbidden, isTrue);
        expect(_makeException(401, null).isForbidden, isFalse);
      });

      test('isNotFound is true for 404', () {
        expect(_makeException(404, null).isNotFound, isTrue);
        expect(_makeException(200, null).isNotFound, isFalse);
      });

      test('isValidationError is true for 400 and 422', () {
        expect(_makeException(400, null).isValidationError, isTrue);
        expect(_makeException(422, null).isValidationError, isTrue);
        expect(_makeException(401, null).isValidationError, isFalse);
      });

      test('isServerError is true for 5xx', () {
        expect(_makeException(500, null).isServerError, isTrue);
        expect(_makeException(503, null).isServerError, isTrue);
        expect(_makeException(404, null).isServerError, isFalse);
      });
    });

    group('toString', () {
      test('includes errorCode when present', () {
        final e = _makeException(400, {'error': 'email-already-in-use'});
        expect(e.toString(), contains('errorCode=email-already-in-use'));
      });

      test('omits errorCode when body is not a Map', () {
        final e = _makeException(500, 'raw error');
        expect(e.toString(), isNot(contains('errorCode')));
      });
    });
  });

  group('NhostNetworkException', () {
    test('wraps the cause exception', () {
      final cause = Exception('Connection refused');
      final e = NhostNetworkException(cause: cause);

      expect(e.cause, same(cause));
    });

    test('is a NhostException', () {
      final e = NhostNetworkException(cause: Exception());
      expect(e, isA<NhostException>());
    });

    test('toString includes the cause', () {
      final e = NhostNetworkException(cause: Exception('DNS failure'));
      expect(e.toString(), contains('DNS failure'));
    });
  });
}
