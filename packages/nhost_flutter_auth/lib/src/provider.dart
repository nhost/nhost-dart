import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nhost_dart/nhost_dart.dart';

/// Exposes Nhost authentication information to its subtree.
class NhostAuthProvider extends InheritedNotifier<AuthNotifier> {
  NhostAuthProvider({
    Key? key,
    required NhostAuthClient auth,
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

  static NhostAuthClient? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NhostAuthProvider>()
        ?.notifier
        ?.value;
  }
}

/// A [Listenable] that notifies when Nhost authentication states changes
class AuthNotifier extends ChangeNotifier
    implements ValueListenable<NhostAuthClient> {
  AuthNotifier(NhostAuthClient auth) : _auth = auth {
    _unsubscribeAuthListener = _auth.addAuthStateChangedCallback(
      (_) => notifyListeners(),
    );
  }

  final NhostAuthClient _auth;
  late UnsubscribeDelegate _unsubscribeAuthListener;

  @override
  void dispose() {
    super.dispose();
    _unsubscribeAuthListener();
  }

  @override
  NhostAuthClient get value => _auth;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is AuthNotifier && other.value == value;
  }
}
