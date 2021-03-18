import 'dart:core';

import 'core_codec.dart';

/// Describes the client's authorization state.
///
/// Many authorization-related API calls return instances of this class. The
/// details of which can be found on specific methods of [Auth].
class AuthResponse {
  AuthResponse({this.session, this.user, this.mfa});
  final Session session;
  final User user;
  final MultiFactorAuthenticationInfo mfa;

  static AuthResponse fromJson(dynamic json) {
    if (json['mfa'] == true) {
      return AuthResponse(mfa: MultiFactorAuthenticationInfo.fromJson(json));
    } else {
      final session = Session.fromJson(json);
      return AuthResponse(session: session, user: session.user);
    }
  }
}

/// Represents a user-authenticated session with Nhost.
class Session {
  Session({
    this.jwtToken,
    this.jwtExpiresIn,
    this.refreshToken,
    this.user,
    this.mfa,
  });

  /// The raw JSON web token
  final String jwtToken;

  /// The amount of time that [jwtToken] will remain valid.
  ///
  /// Measured from the time of issue.
  final Duration jwtExpiresIn;

  /// A token that can be used to periodically refresh the session.
  ///
  /// This value is managed automatically by the [Auth] class.
  final String refreshToken;

  /// The user associated with this session.
  final User user;

  /// Multi-factor Authentication information.
  ///
  /// This field will be `null` if MFA is not enabled for the user.
  final MultiFactorAuthenticationInfo mfa;

  Session copyWith({
    String jwtToken,
    Duration jwtExpiresIn,
    String refreshToken,
    User user,
    MultiFactorAuthenticationInfo mfa,
  }) {
    return Session(
      jwtToken: jwtToken ?? this.jwtToken,
      jwtExpiresIn: jwtExpiresIn ?? this.jwtExpiresIn,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      mfa: mfa ?? this.mfa,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'jwt_token': jwtToken,
      'jwt_expires_in': durationToMs(jwtExpiresIn),
      'refresh_token': refreshToken,
      'user': user?.toJson(),
      'mfa': mfa?.toJson(),
    };
  }

  static Session fromJson(dynamic json) {
    return Session(
      jwtToken: json['jwt_token'] as String,
      jwtExpiresIn: durationFromMs(json['jwt_expires_in'] as int),
      refreshToken: json['refresh_token'] as String,
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      mfa: json['mfa'] == null
          ? null
          : MultiFactorAuthenticationInfo.fromJson(
              json['mfa'] as Map<String, dynamic>),
    );
  }
}

/// Describes an Nhost user.
class User {
  User({
    this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  /// A UUID identifying the user
  final String id;

  /// The user's email address
  final String email;

  /// The user's preferred name for display, or `null` if none
  final String displayName;

  /// A [Uri] locating the user's avatar image, or `null` if none.
  final Uri avatarUrl;

  static User fromJson(dynamic json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] == null
          ? null
          : Uri.parse(json['avatar_url'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl?.toString(),
    };
  }
}

/// Describes information required to perform an MFA login.
class MultiFactorAuthenticationInfo {
  MultiFactorAuthenticationInfo({this.ticket});

  /// Ticket string to be provided to [Auth.completeMfaLogin] in order to continue the
  /// login process
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
  MultiFactorAuthResponse({this.qrCode, this.otpSecret});

  /// Data URI of the QR code that describes a user's OTP generation.
  ///
  /// This value, when presented to the user, can be read by authenticator apps
  /// to set up OTP.
  final UriData qrCode;

  /// OTP secret
  final String otpSecret;

  static MultiFactorAuthResponse fromJson(dynamic json) {
    return MultiFactorAuthResponse(
      qrCode: uriDataFromString(json['image_url'] as String),
      otpSecret: json['otp_secret'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'image_url': uriDataToString(qrCode),
      'otp_secret': otpSecret,
    };
  }
}
