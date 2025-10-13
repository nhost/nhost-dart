import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('DeanonymizeOptions', () {
    group('toJson', () {
      test('should serialize email-password method correctly', () {
        final options = DeanonymizeOptions(
          signInMethod: DeanonymizeSignInMethod.emailPassword,
          email: 'test@example.com',
          password: 'password123',
        );

        final json = options.toJson();

        expect(json['signInMethod'], equals('email-password'));
        expect(json['email'], equals('test@example.com'));
        expect(json['password'], equals('password123'));
        expect(json['options'], isA<Map>());
      });

      test('should serialize passwordless method correctly', () {
        final options = DeanonymizeOptions(
          signInMethod: DeanonymizeSignInMethod.passwordless,
          email: 'test@example.com',
        );

        final json = options.toJson();

        expect(json['signInMethod'], equals('passwordless'));
        expect(json['email'], equals('test@example.com'));
        expect(json.containsKey('password'), isFalse);
      });

      test('should include optional fields when provided', () {
        final options = DeanonymizeOptions(
          signInMethod: DeanonymizeSignInMethod.emailPassword,
          email: 'test@example.com',
          password: 'password123',
          allowedRoles: ['user', 'admin'],
          defaultRole: 'user',
          displayName: 'Test User',
          locale: 'en',
          metadata: {'key': 'value'},
          redirectTo: Uri.parse('https://example.com/callback'),
        );

        final json = options.toJson();
        final optionsMap = json['options'] as Map<String, dynamic>;

        expect(optionsMap['allowedRoles'], equals(['user', 'admin']));
        expect(optionsMap['defaultRole'], equals('user'));
        expect(optionsMap['displayName'], equals('Test User'));
        expect(optionsMap['locale'], equals('en'));
        expect(optionsMap['metadata'], equals({'key': 'value'}));
        expect(
            optionsMap['redirectTo'], equals('https://example.com/callback'));
      });

      test('should not include optional fields when not provided', () {
        final options = DeanonymizeOptions(
          signInMethod: DeanonymizeSignInMethod.passwordless,
          email: 'test@example.com',
        );

        final json = options.toJson();
        final optionsMap = json['options'] as Map<String, dynamic>;

        expect(optionsMap.containsKey('allowedRoles'), isFalse);
        expect(optionsMap.containsKey('defaultRole'), isFalse);
        expect(optionsMap.containsKey('displayName'), isFalse);
        expect(optionsMap.containsKey('locale'), isFalse);
        expect(optionsMap.containsKey('metadata'), isFalse);
        expect(optionsMap.containsKey('redirectTo'), isFalse);
      });

      group('validation', () {
        test('should throw when password is too short', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.emailPassword,
            email: 'test@example.com',
            password: 'ab',
          );

          expect(
            () => options.toJson(),
            throwsA(isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Must be between 3 and 50 characters'),
            )),
          );
        });

        test('should throw when password is too long', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.emailPassword,
            email: 'test@example.com',
            password: 'a' * 51,
          );

          expect(
            () => options.toJson(),
            throwsA(isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Must be between 3 and 50 characters'),
            )),
          );
        });

        test('should accept password with exactly 3 characters', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.emailPassword,
            email: 'test@example.com',
            password: 'abc',
          );

          expect(() => options.toJson(), returnsNormally);
        });

        test('should accept password with exactly 50 characters', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.emailPassword,
            email: 'test@example.com',
            password: 'a' * 50,
          );

          expect(() => options.toJson(), returnsNormally);
        });

        test('should not throw when password is null', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.passwordless,
            email: 'test@example.com',
          );

          expect(() => options.toJson(), returnsNormally);
        });

        test('should throw when locale is not 2 characters', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.passwordless,
            email: 'test@example.com',
            locale: 'eng',
          );

          expect(
            () => options.toJson(),
            throwsA(isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Must be a 2-character locale'),
            )),
          );
        });

        test('should accept valid 2-character locale', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.passwordless,
            email: 'test@example.com',
            locale: 'en',
          );

          expect(() => options.toJson(), returnsNormally);
        });

        test('should throw when displayName is too long', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.passwordless,
            email: 'test@example.com',
            displayName: 'a' * 33,
          );

          expect(
            () => options.toJson(),
            throwsA(isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Must be at most 32 characters'),
            )),
          );
        });

        test('should accept displayName with exactly 32 characters', () {
          final options = DeanonymizeOptions(
            signInMethod: DeanonymizeSignInMethod.passwordless,
            email: 'test@example.com',
            displayName: 'a' * 32,
          );

          expect(() => options.toJson(), returnsNormally);
        });
      });
    });

    group('DeanonymizeSignInMethod', () {
      test('should serialize email-password correctly', () {
        expect(
          DeanonymizeSignInMethod.emailPassword.serialized,
          equals('email-password'),
        );
      });

      test('should serialize passwordless correctly', () {
        expect(
          DeanonymizeSignInMethod.passwordless.serialized,
          equals('passwordless'),
        );
      });
    });
  });
}
