library nhost_flutter_auth;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nhost_dart_sdk/client.dart';

/// Exposes Nhost authentication information to its subtree.
///
/// TODO...
class NhostAuth extends InheritedNotifier<_AuthNotifier> {
  NhostAuth({
    Key key,
    @required Auth auth,
    @required Widget child,
  })  : assert(auth != null),
        super(
          key: key,
          notifier: _AuthNotifier(auth),
          child: child,
        );

  @override
  bool updateShouldNotify(InheritedNotifier<_AuthNotifier> oldWidget) {
    return oldWidget.notifier != notifier;
  }

  static Auth of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NhostAuth>()
        .notifier
        .value;
  }
}

/// A [Listenable] that notifies when Nhost authentication states changes
class _AuthNotifier extends ChangeNotifier implements ValueListenable<Auth> {
  _AuthNotifier(Auth auth) : _auth = auth {
    _unsubscribeAuthListener =
        _auth.addAuthStateChangedCallback(({authenticated}) {
      notifyListeners();
    });
  }

  final Auth _auth;
  UnsubscribeDelegate _unsubscribeAuthListener;

  @override
  void dispose() {
    super.dispose();
    _unsubscribeAuthListener();
  }

  @override
  Auth get value => _auth;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is _AuthNotifier && other.value == value;
  }
}
