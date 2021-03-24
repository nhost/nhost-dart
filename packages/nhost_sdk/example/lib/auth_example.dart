import 'package:nhost_sdk/nhost_sdk.dart';

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';

void main() async {
  // Setup
  final client = NhostClient(baseUrl: nhostApiUrl);

  // Login
  await loginOrRegister(client,
      email: 'user-1@nhost.io', password: 'password-1');

  // Print out a few details about the current user
  final currentUser = client.auth.currentUser;
  print('currentUser.id: ${currentUser.id}');
  print('currentUser.displayName: ${currentUser.displayName}');
  print('currentUser.email: ${currentUser.email}');

  // And logout
  await client.auth.logout();

  // Release
  client.close();
}

Future<void> loginOrRegister(
  NhostClient client, {
  String email,
  String password,
}) async {
  try {
    return await client.auth.login(email: email, password: password);
  } on ApiException {
    // Login failed, so try to register instead
  }
  await client.auth.register(email: email, password: password);
}
