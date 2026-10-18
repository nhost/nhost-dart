import 'package:flutter/widgets.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
// Redundant under the melos path overrides, but the published nhost_dart does
// not re-export User yet, so the type has to come from nhost_sdk directly.
// ignore: unnecessary_import
import 'package:nhost_sdk/nhost_sdk.dart' show User;

/// Builds a widget using the currently authenticated [User].
///
/// Renders [orElse] (default: [SizedBox.shrink]) when the user is not signed
/// in or authentication is still loading.
///
/// Must be a descendant of [NhostAuthProvider].
class NhostUserBuilder extends StatelessWidget {
  const NhostUserBuilder({super.key, required this.builder, this.orElse});

  final Widget Function(BuildContext context, User user) builder;
  final WidgetBuilder? orElse;

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    final user = auth.currentUser;
    if (auth.authenticationState == AuthenticationState.signedIn &&
        user != null) {
      return builder(context, user);
    }
    return orElse?.call(context) ?? const SizedBox.shrink();
  }
}
