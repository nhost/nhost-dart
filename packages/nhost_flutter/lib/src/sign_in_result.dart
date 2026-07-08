import 'package:nhost_dart/nhost_dart.dart';

/// The outcome of an email-password sign-in attempt.
///
/// Use with [NhostAuthClientSignInX.signIn] and an exhaustive switch to handle
/// every case without guessing at nullable fields:
///
/// ```dart
/// final result = await Nhost.instance.auth.signIn(
///   email: email,
///   password: password,
/// );
/// switch (result) {
///   case SignInSuccess():
///     // auth state updated — navigate to home
///   case SignInNeedsMfa(:final ticket):
///     // navigate to MFA screen, pass ticket to completeMfaSignIn()
///   case SignInNeedsEmailVerification():
///     // show "check your inbox" message
/// }
/// ```
sealed class SignInResult {
  const SignInResult();
}

/// Sign-in succeeded. The session is active and [user] is authenticated.
class SignInSuccess extends SignInResult {
  SignInSuccess({required this.session, required this.user});
  final Session session;
  final User user;
}

/// The account has MFA enabled. Call [NhostAuthClient.completeMfaSignIn] with
/// [ticket] and the TOTP code from the authenticator app to finish signing in.
class SignInNeedsMfa extends SignInResult {
  SignInNeedsMfa({required this.ticket});

  /// Opaque ticket string — pass it to [NhostAuthClient.completeMfaSignIn].
  final String ticket;
}

/// The account email has not been verified yet. The server blocked sign-in
/// until verification is complete. Show a "check your inbox" message and
/// optionally call [NhostAuthClient.sendVerificationEmail] to resend.
class SignInNeedsEmailVerification extends SignInResult {
  const SignInNeedsEmailVerification();
}

/// Typed sign-in extension on [NhostAuthClient].
///
/// Wraps [NhostAuthClient.signInEmailPassword] and maps the ambiguous
/// `AuthResponse` (multiple nullable fields) into an exhaustive sealed type.
///
/// Failures (wrong password, network error, etc.) still throw — typically
/// [ApiException] — so wrap the call in try/catch as usual.
extension NhostAuthClientSignInX on NhostAuthClient {
  /// Signs in with [email] and [password], returning a [SignInResult] that
  /// covers every possible outcome without nullable field inspection.
  ///
  /// Throws [ApiException] on server-side failures (wrong password, banned
  /// account, etc.) and rethrows any network-level exceptions unchanged.
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    final res = await signInEmailPassword(email: email, password: password);

    if (res.mfa != null) {
      return SignInNeedsMfa(ticket: res.mfa!.ticket);
    }

    if (res.session != null) {
      return SignInSuccess(
        session: res.session!,
        user: res.session!.user!,
      );
    }

    return const SignInNeedsEmailVerification();
  }
}
