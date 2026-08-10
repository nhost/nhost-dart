import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nhost_dart/nhost_dart.dart';

import 'auth_state.dart';

extension NhostAuthClientFlutterX on NhostAuthClient {
  static final _state = Expando<_AuthFlutterState>();

  _AuthFlutterState get _flutterState =>
      _state[this] ??= _AuthFlutterState(this);

  /// A broadcast [Stream] that emits an [AuthState] on every authentication
  /// state change.
  Stream<AuthState> get authStateChanges => _flutterState.stream;

  /// A [ValueListenable] that always holds the current [AuthState].
  ValueListenable<AuthState> get authStateListenable => _flutterState.notifier;
}

class _AuthFlutterState {
  _AuthFlutterState(NhostAuthClient auth) : _auth = auth {
    _notifier = ValueNotifier(_mapCurrentState());
    _controller = StreamController<AuthState>.broadcast();
    _unsubscribe = auth.addAuthStateChangedCallback((_) {
      final mapped = _mapCurrentState();
      _notifier.value = mapped;
      _controller.add(mapped);
    });
  }

  final NhostAuthClient _auth;
  late final StreamController<AuthState> _controller;
  late final ValueNotifier<AuthState> _notifier;
  late final UnsubscribeDelegate _unsubscribe;

  Stream<AuthState> get stream => _controller.stream;
  ValueListenable<AuthState> get notifier => _notifier;

  AuthState _mapCurrentState() => switch (_auth.authenticationState) {
        AuthenticationState.inProgress => const AuthStateLoading(),
        AuthenticationState.signedOut => const AuthStateSignedOut(),
        AuthenticationState.signedIn => AuthStateSignedIn(
            user: _auth.currentUser!,
            session: _auth.userSession.session!,
          ),
      };

  void dispose() {
    _unsubscribe();
    _controller.close();
    _notifier.dispose();
  }
}
