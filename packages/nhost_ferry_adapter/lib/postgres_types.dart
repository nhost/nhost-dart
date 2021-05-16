import 'package:built_value/serializer.dart';

class TimestamptzSerializer implements PrimitiveSerializer<DateTime> {
  @override
  Iterable<Type> get types => [DateTime];

  @override
  String get wireName => 'timestamptz';

  @override
  Object serialize(
    Serializers serializers,
    DateTime object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return object.toIso8601String();
  }

  @override
  DateTime deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return DateTime.parse(serialized.toString());
  }
}

class UuidSerializer implements PrimitiveSerializer<String> {
  @override
  Iterable<Type> get types => [String];

  @override
  String get wireName => 'uuid';

  @override
  Object serialize(
    Serializers serializers,
    String object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return object;
  }

  @override
  String deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serialized as String;
  }
}
