import 'package:flutter/widgets.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

/// Shows [child] only when a user is authenticated. Renders [orElse]
/// (default: [SizedBox.shrink]) when signed out or loading.
///
/// Must be a descendant of [NhostAuthProvider].
class NhostSignedIn extends StatelessWidget {
  const NhostSignedIn({super.key, required this.child, this.orElse});

  final Widget child;
  final Widget? orElse;

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    if (auth.authenticationState == AuthenticationState.signedIn) {
      return child;
    }
    return orElse ?? const SizedBox.shrink();
  }
}
