import 'package:nhost_auth_dart/nhost_auth_dart.dart';

/// https://github.com/nhost/nhost-dart/#running-the-example-server
const subdomain = 'localhost:1337';
const region = '';
const authUrl = 'https://localhost:1337/v1/auth';
const storageUrl = 'https://localhost:1337/v1/storage';

Future<void> signInOrSignUp(
  HasuraAuthClient hasuraAuthClient, {
  required String email,
  required String password,
}) async {
  try {
    await hasuraAuthClient.signInEmailPassword(
      email: email,
      password: password,
    );
    return;
  } on ApiException catch (e) {
    print('Sign in failed, so try to register instead');
    print(e);
    await hasuraAuthClient.signUp(
      email: email,
      password: password,
    );
  } catch (e, st) {
    print(e);
    print(st);
  }
}
