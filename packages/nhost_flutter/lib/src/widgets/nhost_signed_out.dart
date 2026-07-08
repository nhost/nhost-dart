import 'package:flutter/widgets.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

/// Shows [child] only when no user is authenticated. Renders [orElse]
/// (default: [SizedBox.shrink]) when signed in or loading.
///
/// Must be a descendant of [NhostAuthProvider].
class NhostSignedOut extends StatelessWidget {
  const NhostSignedOut({super.key, required this.child, this.orElse});

  final Widget child;
  final Widget? orElse;

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    if (auth.authenticationState == AuthenticationState.signedOut) {
      return child;
    }
    return orElse ?? const SizedBox.shrink();
  }
}
