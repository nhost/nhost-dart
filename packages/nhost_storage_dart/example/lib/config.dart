import 'package:nhost_auth_dart/nhost_auth_dart.dart';

/// https://github.com/nhost/nhost-dart/#running-the-example-server
const subdomain = 'localhost:1337';
const region = '';

Future<void> signInOrSignUp(
  AuthClient authClient, {
  required String email,
  required String password,
}) async {
  try {
    await authClient.signInEmailPassword(email: email, password: password);
    return;
  } on ApiException catch (e) {
    print('Sign in failed, so try to register instead');
    print(e);
    await authClient.signUp(email: email, password: password);
  } catch (e, st) {
    print(e);
    print(st);
  }
}
