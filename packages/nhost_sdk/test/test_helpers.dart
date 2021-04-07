import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:otp/otp.dart';

const defaultTestEmail = 'user-1@nhost.io';
const defaultTestPassword = 'password-1';

const basicTestFileContents = 'abcdef';

// Registers a basic user for test setup. The auth object will be left in a
// logged out state.
Future<void> registerTestUser(Auth auth) async {
  await auth.register(email: defaultTestEmail, password: defaultTestPassword);
  await auth.logout();
}

// Register and logs in a basic user for test setup. The auth object will be
// left in a logged out state.
Future<void> registerAndLoginBasicUser(Auth auth) async {
  await auth.register(email: defaultTestEmail, password: defaultTestPassword);
}

// Registers an MFA user for test setup, logs them out, and returns the OTP
// secret.
Future<String> registerMfaUser(Auth auth, {bool logout = true}) async {
  await auth.register(email: defaultTestEmail, password: defaultTestPassword);
  final mfaDetails = await auth.generateMfa();
  await auth.enableMfa(totpFromSecret(mfaDetails.otpSecret));
  if (logout) await auth.logout();
  return mfaDetails.otpSecret;
}

/// Creates a new time-based one-time-pass based on the provided secret and the
/// current time.
String totpFromSecret(String otpSecret) => OTP
    .generateTOTPCode(otpSecret, DateTime.now().millisecondsSinceEpoch)
    .toString();
