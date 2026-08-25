import 'package:flutter/widgets.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

/// Routes to different widgets based on the current authentication state.
///
/// Must be a descendant of [NhostAuthProvider].
///
/// ```dart
/// NhostAuthGate(
///   loading:   (context) => const SplashScreen(),
///   signedOut: (context) => const LoginScreen(),
///   signedIn:  (context, user, session) => HomeScreen(user: user),
/// )
/// ```
class NhostAuthGate extends StatelessWidget {
  const NhostAuthGate({
    super.key,
    required this.signedOut,
    required this.signedIn,
    this.loading,
  });

  /// Builder shown while authentication state is being determined.
  /// Defaults to [SizedBox.shrink].
  final WidgetBuilder? loading;

  /// Builder shown when no user is authenticated.
  final WidgetBuilder signedOut;

  /// Builder shown when a user is authenticated.
  final Widget Function(BuildContext context, User user, Session session)
      signedIn;

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    return switch (auth.authenticationState) {
      AuthenticationState.inProgress =>
        loading?.call(context) ?? const SizedBox.shrink(),
      AuthenticationState.signedOut => signedOut(context),
      AuthenticationState.signedIn =>
        signedIn(context, auth.currentUser!, auth.userSession.session!),
    };
  }
}
