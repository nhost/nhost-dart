import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nhost_sdk/nhost_sdk.dart';

/// Exposes Nhost authentication information to its subtree.
class NhostAuthProvider extends InheritedNotifier<AuthNotifier> {
  NhostAuthProvider({
    Key? key,
    required AuthClient auth,
    required Widget child,
  }) : super(
          key: key,
          notifier: AuthNotifier(auth),
          child: child,
        );

  @override
  bool updateShouldNotify(InheritedNotifier<AuthNotifier> oldWidget) {
    return oldWidget.notifier != notifier;
  }

  static AuthClient? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NhostAuthProvider>()
        ?.notifier
        ?.value;
  }
}

/// A [Listenable] that notifies when Nhost authentication states changes
class AuthNotifier extends ChangeNotifier
    implements ValueListenable<AuthClient> {
  AuthNotifier(AuthClient auth) : _auth = auth {
    _unsubscribeAuthListener = _auth.addAuthStateChangedCallback(
      (_) => notifyListeners(),
    );
  }

  final AuthClient _auth;
  late UnsubscribeDelegate _unsubscribeAuthListener;

  @override
  void dispose() {
    super.dispose();
    _unsubscribeAuthListener();
  }

  @override
  AuthClient get value => _auth;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is AuthNotifier && other.value == value;
  }
}
