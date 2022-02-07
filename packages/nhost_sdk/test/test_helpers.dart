import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:otp/otp.dart';

const defaultTestEmail = 'user-1@nhost.io';
const defaultTestPassword = 'password-1';
final defaultCreatedAt = DateTime(1983);

const basicTestFileContents = 'abcdef';

User createTestUser({required String id, required String email}) {
  return User(
    id: id,
    displayName: email,
    locale: 'en-ca',
    createdAt: defaultCreatedAt,
    defaultRole: 'user',
    roles: ['user'],
    isAnonymous: false,
  );
}

// Registers a basic user for test setup. The auth object will be left in a
// logged out state.
Future<void> registerTestUser(AuthClient auth) async {
  await auth.signUp(email: defaultTestEmail, password: defaultTestPassword);
  await auth.signOut();
}

// Register and logs in a basic user for test setup. The auth object will be
// left in a logged in state.
Future<AuthResponse> registerAndSignInBasicUser(AuthClient auth) async {
  return await auth.signUp(
      email: defaultTestEmail, password: defaultTestPassword);
}

// Registers an MFA user for test setup, logs them out, and returns the OTP
// secret.
Future<String> registerMfaUser(AuthClient auth, {bool signOut = true}) async {
  await auth.signUp(email: defaultTestEmail, password: defaultTestPassword);
  final mfaDetails = await auth.generateMfa();
  await auth.enableMfa(totpFromSecret(mfaDetails.totpSecret));
  if (signOut) await auth.signOut();
  return mfaDetails.totpSecret;
}

/// Creates a new time-based one-time-pass based on the provided secret and the
/// current time.
String totpFromSecret(String otpSecret) {
  return OTP.generateTOTPCodeString(
    otpSecret,
    DateTime.now().millisecondsSinceEpoch,
    algorithm: Algorithm.SHA1,
    isGoogle: true,
  );
}
