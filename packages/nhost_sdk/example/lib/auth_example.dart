import 'package:nhost_sdk/nhost_sdk.dart';

import 'config.dart';

void main() async {
  // Setup
  final client = NhostClient(backendUrl: nhostUrl);
  try {
    await signInOrSignUp(
      client,
      email: 'user-1@nhost.io',
      password: 'password-1',
    );
    // Print out a few details about the current user
    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      print('currentUser.id: ${currentUser.id}');
      print('currentUser.displayName: ${currentUser.displayName}');
      print('currentUser.email: ${currentUser.email}');
      // And logout
      await client.auth.signOut();
    }
  } catch (e) {
    print(e);
  }
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
  } on ApiException catch (e) {
    print('Sign in failed, so try to register instead');
    print(e);
    await client.auth.signUp(email: email, password: password);
  } catch (e, st) {
    print(e);
    print(st);
  }
}
