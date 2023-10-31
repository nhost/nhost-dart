import 'package:nhost_auth_dart/nhost_auth_dart.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:otp/otp.dart';

const defaultTestEmail = 'user-1@nhost.io';

String getTestEmail() {
  var now = DateTime.now().millisecondsSinceEpoch;
  return "user-$now@nhost.io";
}

const defaultTestPhone = '289-289-2899';
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
    metadata: {'age': 14, 'height': 162},
  );
}

// Registers a basic user for test setup. The auth object will be left in a
// logged out state.
Future<void> registerTestUser(
    NhostAuthClient auth, String email, String password) async {
  await auth.signUp(email: email, password: password);
  await auth.signOut();
}

// Register and logs in a basic user for test setup. The auth object will be
// left in a logged in state.
Future<AuthResponse> registerAndSignInBasicUser(
    NhostAuthClient auth, String email, String password) async {
  return await auth.signUp(email: email, password: password);
}

// Registers an MFA user for test setup, logs them out, and returns the OTP
// secret.
Future<String> registerMfaUser(
    NhostAuthClient auth, String email, String password,
    {bool signOut = true}) async {
  await auth.signUp(email: email, password: password);
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
