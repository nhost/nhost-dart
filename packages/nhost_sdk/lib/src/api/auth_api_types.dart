import 'dart:core';

import 'core_codec.dart';

/// Describes the client's authorization state.
///
/// Many authorization-related API calls return instances of this class. The
/// details of which can be found on specific methods of [Auth].
class AuthResponse {
  AuthResponse({this.session, this.mfa});

  final Session? session;
  final MultiFactorAuthenticationInfo? mfa;
  User? get user => session?.user;

  static AuthResponse fromJson(dynamic json) {
    return AuthResponse(
      session:
          json['session'] != null ? Session.fromJson(json['session']) : null,
      mfa: json['mfa'] != null
          ? MultiFactorAuthenticationInfo.fromJson(json['mfa'])
          : null,
    );
  }
}

/// Represents a user-authenticated session with Nhost.
class Session {
  Session({
    this.accessToken,
    this.accessTokenExpiresIn,
    this.refreshToken,
    this.user,
  });

  /// The raw JSON web token
  final String? accessToken;

  /// The amount of time that [accessToken] will remain valid.
  ///
  /// Measured from the time of issue in Seconds.
  final Duration? accessTokenExpiresIn;

  /// A token that can be used to periodically refresh the session.
  ///
  /// This value is managed automatically by the [Auth] class.
  final String? refreshToken;

  /// The user associated with this session.
  final User? user;

  Session copyWith({
    String? accessToken,
    Duration? accessTokenExpiresIn,
    String? refreshToken,
    User? user,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      accessTokenExpiresIn: accessTokenExpiresIn ?? this.accessTokenExpiresIn,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'accessTokenExpiresIn': durationToSeconds(accessTokenExpiresIn),
      'refreshToken': refreshToken,
      'user': user?.toJson(),
    };
  }

  static Session fromJson(dynamic json) {
    return Session(
      accessToken: json['accessToken'] as String?,
      accessTokenExpiresIn:
          durationFromSeconds(json['accessTokenExpiresIn'] as int?),
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Describes an Nhost user.
class User {
  User({
    required this.id,
    required this.displayName,
    required this.locale,
    required this.createdAt,
    required this.isAnonymous,
    required this.defaultRole,
    required this.roles,
    this.metadata,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String displayName;

  /// A [Uri] locating the user's avatar image, or `null` if none
  final Uri? avatarUrl;
  final String locale;
  final DateTime createdAt;

  final bool isAnonymous;
  final String defaultRole;
  final List<String> roles;
  final Map<String, Object?>? metadata;

  static User fromJson(dynamic json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      locale: json['locale'] as String,
      avatarUrl: json['avatarUrl'] == null
          ? null
          : Uri.parse(json['avatarUrl'] as String),
      createdAt: DateTime.parse(json['createdAt']),
      isAnonymous: json['isAnonymous'] as bool,
      defaultRole: json['defaultRole'] as String,
      roles: <String>[...json['roles']],
      metadata: json['metadata'] == null
          ? null
          : <String, Object?>{...json['metadata']},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl?.toString(),
      'locale': locale,
      'createdAt': createdAt.toIso8601String(),
      'isAnonymous': isAnonymous,
      'defaultRole': defaultRole,
      'metadata': metadata,
      'roles': roles,
    };
  }

  @override
  String toString() {
    return {
      'id': id,
      'displayName': displayName,
      'locale': locale,
      'createdAt': createdAt,
      'isAnonymous': isAnonymous,
      'defaultRole': defaultRole,
      'roles': roles,
      'metadata': metadata,
      'email': email,
      'avatarUrl': avatarUrl,
    }.toString();
  }
}

/// Describes information required to perform an MFA sign in.
class MultiFactorAuthenticationInfo {
  MultiFactorAuthenticationInfo({required this.ticket});

  /// Ticket string to be provided to [AuthClient.completeMfaSignIn] in order
  /// to continue the sign in process
  final String ticket;

  static MultiFactorAuthenticationInfo fromJson(dynamic json) {
    return MultiFactorAuthenticationInfo(
      ticket: json['ticket'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ticket': ticket,
    };
  }
}

class MultiFactorAuthResponse {
  MultiFactorAuthResponse({required this.imageUrl, required this.totpSecret});

  /// Data URI of the QR code that describes a user's OTP generation.
  ///
  /// This value, when presented to the user, can be read by authenticator apps
  /// to set up OTP.
  final UriData imageUrl;

  /// OTP secret
  final String totpSecret;

  static MultiFactorAuthResponse fromJson(dynamic json) {
    return MultiFactorAuthResponse(
      imageUrl: uriDataFromString(json['imageUrl'] as String)!,
      totpSecret: json['totpSecret'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'imageUrl': uriDataToString(imageUrl),
      'totpSecret': totpSecret,
    };
  }
}
