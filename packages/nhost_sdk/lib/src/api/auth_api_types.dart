import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import 'core_codec.dart';

part 'auth_api_types.g.dart';

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

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Session {
  Session({
    this.jwtToken,
    this.jwtExpiresIn,
    this.refreshToken,
    this.user,
    this.mfa,
  });

  final String jwtToken;
  @JsonKey(
    fromJson: durationFromMs,
    toJson: durationToMs,
  )
  final Duration jwtExpiresIn;
  final String refreshToken;
  final User user;

  /// Multi-factor Authentication information.
  ///
  /// This field will be `null` if MFA is not enabled for the user.
  final MultiFactorAuthenticationInfo mfa;

  static Session fromJson(dynamic json) => _$SessionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class User {
  User({this.id, this.displayName, this.email});

  final String id;
  final String displayName;
  final String email;

  static User fromJson(dynamic json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

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

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MultiFactorAuthResponse {
  MultiFactorAuthResponse({this.qrCode, this.otpSecret});

  /// Base64 data: image of the QR code
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
