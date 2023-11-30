import 'package:nhost_auth_dart/nhost_auth_dart.dart';

/// https://github.com/nhost/nhost-dart/#running-the-example-server
const subdomain = 'local';
const region = '';
const authUrl = 'https://local.auth.nhost.run';
const storageUrl = 'https://local.storage.nhost.run';

Future<void> signInOrSignUp(
  NhostAuthClient nhostAuthClient, {
  required String email,
  required String password,
}) async {
  try {
    await nhostAuthClient.signInEmailPassword(
      email: email,
      password: password,
    );
    return;
  } on ApiException catch (e) {
    print('Sign in failed, so try to register instead');
    print(e);
    await nhostAuthClient.signUp(
      email: email,
      password: password,
    );
  } catch (e, st) {
    print(e);
    print(st);
  }
}
