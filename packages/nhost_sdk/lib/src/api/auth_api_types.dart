import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import 'core_codec.dart';

part 'auth_api_types.g.dart';

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
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
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
  @JsonKey(
    fromJson: durationFromMs,
    toJson: durationToMs,
  )
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

  static Session fromJson(dynamic json) => _$SessionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

/// Describes an Nhost user.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class User {
  User({
    this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
  });

  /// A GUID identifying the user
  final String id;

  /// The user's preferred name for display
  final String displayName;

  /// The user's email address
  final String email;

  /// A [Uri] locating the user's avatar image, or `null` if none.
  final Uri avatarUrl;

  static User fromJson(dynamic json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

/// Describes information required to perform an MFA login.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MultiFactorAuthenticationInfo {
  MultiFactorAuthenticationInfo({this.ticket});

  /// Ticket string to be provided to [Auth.mfaTotp] in order to continue the
  /// login process
  final String ticket;

  static MultiFactorAuthenticationInfo fromJson(Map<String, dynamic> json) =>
      _$MultiFactorAuthenticationInfoFromJson(json);
  Map<String, dynamic> toJson() => _$MultiFactorAuthenticationInfoToJson(this);
}

///
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MultiFactorAuthResponse {
  MultiFactorAuthResponse({this.qrCode, this.otpSecret});

  /// Data URI of the QR code that describes a user's OTP generation.
  ///
  /// This value, when presented to the user, can be read by authenticator apps
  /// to set up OTP.
  @JsonKey(
    name: 'image_url',
    fromJson: uriDataFromString,
    toJson: uriDataToString,
  )
  final UriData qrCode;

  /// OTP secret
  final String otpSecret;

  static MultiFactorAuthResponse fromJson(dynamic json) =>
      _$MultiFactorAuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MultiFactorAuthResponseToJson(this);
}
