import 'package:nhost_auth_dart/nhost_auth_dart.dart';

import 'config.dart';

void main() async {
  // Setup
  final auth = AuthClient(
    subdomain: Subdomain(
      subdomain: subdomain,
      region: region,
    ),
  );

  try {
    await signInOrSignUp(
      auth,
      email: 'user-1@nhost.io',
      password: 'password-1',
    );
    // Print out a few details about the current user
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      print('currentUser.id: ${currentUser.id}');
      print('currentUser.displayName: ${currentUser.displayName}');
      print('currentUser.email: ${currentUser.email}');
      // And logout
      await auth.signOut();
    }
  } catch (e) {
    print(e);
  }

  // Release
  auth.close();
}

Future<void> signInOrSignUp(
  AuthClient auth, {
  required String email,
  required String password,
}) async {
  try {
    await auth.signInEmailPassword(email: email, password: password);
    return;
  } on ApiException catch (e) {
    print('Sign in failed, so try to register instead');
    print(e);
    await auth.signUp(email: email, password: password);
  } catch (e, st) {
    print(e);
    print(st);
  }
}
