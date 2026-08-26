import 'package:nhost_dart/nhost_dart.dart';

import 'auth_state.dart';

/// Maps [auth]'s current authentication state onto an [AuthState].
///
/// [AuthenticationState.signedIn] does not guarantee that both a user and a
/// session are available: it flips as soon as `userSession.session` is set, but
/// `Session.user` is nullable and a `/token` refresh can return a session
/// without one. Rather than unwrapping and throwing on that path — which is the
/// startup/refresh path — a missing user or session is reported as
/// [AuthStateLoading], so callers keep showing their loading UI until the
/// session is fully resolved.
AuthState authStateOf(NhostAuthClient auth) {
  switch (auth.authenticationState) {
    case AuthenticationState.inProgress:
      return const AuthStateLoading();
    case AuthenticationState.signedOut:
      return const AuthStateSignedOut();
    case AuthenticationState.signedIn:
      final user = auth.currentUser;
      final session = auth.userSession.session;
      if (user == null || session == null) {
        return const AuthStateLoading();
      }
      return AuthStateSignedIn(user: user, session: session);
  }
}
