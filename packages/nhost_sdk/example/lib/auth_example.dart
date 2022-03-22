import 'package:nhost_sdk/nhost_sdk.dart';

import 'config.dart';

void main() async {
  // Setup
  final client = NhostClient(backendUrl: nhostUrl);
  await signInOrSignUp(client,
      email: 'user-1@nhost.io', password: 'password-1');

  // Print out a few details about the current user
  final currentUser = client.auth.currentUser!;
  print('currentUser.id: ${currentUser.id}');
  print('currentUser.displayName: ${currentUser.displayName}');
  print('currentUser.email: ${currentUser.email}');

  // And logout
  await client.auth.signOut();

  // Release
  client.close();
}

Future<void> signInOrSignUp(
  NhostClient client, {
  required String email,
  required String password,
}) async {
  try {
    await client.auth.signInEmailPassword(email: email, password: password);
    return;
  } on ApiException {
    // Sign in failed, so try to register instead
  }
  await client.auth.signUp(email: email, password: password);
}
