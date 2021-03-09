// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) {
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

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
      'jwt_token': instance.jwtToken,
      'jwt_expires_in': durationToMs(instance.jwtExpiresIn),
      'refresh_token': instance.refreshToken,
      'user': instance.user?.toJson(),
      'mfa': instance.mfa?.toJson(),
    };

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    email: json['email'] as String,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'email': instance.email,
    };

MultiFactorAuthenticationInfo _$MultiFactorAuthenticationInfoFromJson(
    Map<String, dynamic> json) {
  return MultiFactorAuthenticationInfo(
    ticket: json['ticket'] as String,
  );
}

Map<String, dynamic> _$MultiFactorAuthenticationInfoToJson(
        MultiFactorAuthenticationInfo instance) =>
    <String, dynamic>{
      'ticket': instance.ticket,
    };

MultiFactorAuthResponse _$MultiFactorAuthResponseFromJson(
    Map<String, dynamic> json) {
  return MultiFactorAuthResponse(
    qrCode: uriDataFromString(json['image_url'] as String),
    otpSecret: json['otp_secret'] as String,
  );
}

Map<String, dynamic> _$MultiFactorAuthResponseToJson(
        MultiFactorAuthResponse instance) =>
    <String, dynamic>{
      'image_url': uriDataToString(instance.qrCode),
      'otp_secret': instance.otpSecret,
    };
