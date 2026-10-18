import 'package:nhost_sdk/nhost_sdk.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

final class AuthStateSignedOut extends AuthState {
  const AuthStateSignedOut();
}

final class AuthStateSignedIn extends AuthState {
  const AuthStateSignedIn({required this.user, required this.session});
  final User user;
  final Session session;
}
