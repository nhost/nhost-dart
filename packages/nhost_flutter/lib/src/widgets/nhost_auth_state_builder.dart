import 'package:flutter/widgets.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

import '../auth_state.dart';

/// Builds a widget tree based on the current [AuthState].
///
/// The [builder] receives a sealed [AuthState] — use an exhaustive `switch`
/// with no `default` case:
///
/// ```dart
/// NhostAuthStateBuilder(
///   builder: (context, state) => switch (state) {
///     AuthStateLoading()             => const SplashScreen(),
///     AuthStateSignedOut()           => const LoginScreen(),
///     AuthStateSignedIn(:final user) => HomeScreen(user: user),
///   },
/// )
/// ```
///
/// Must be a descendant of [NhostAuthProvider].
class NhostAuthStateBuilder extends StatelessWidget {
  const NhostAuthStateBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, AuthState state) builder;

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    final state = switch (auth.authenticationState) {
      AuthenticationState.inProgress => const AuthStateLoading(),
      AuthenticationState.signedOut => const AuthStateSignedOut(),
      AuthenticationState.signedIn => AuthStateSignedIn(
          user: auth.currentUser!,
          session: auth.userSession.session!,
        ),
    };
    return builder(context, state);
  }
}
