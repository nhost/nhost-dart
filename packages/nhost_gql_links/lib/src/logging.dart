import 'package:gql/ast.dart';
import 'package:logging/logging.dart';

/// Logs package events
final log = Logger('nhost.gql_links');

/// Extension to expose a method for the logging of operations
extension OperationDefinitionListLogging on List<OperationDefinitionNode> {
  String toLogString() {
    final sb = StringBuffer();
    sb
      ..write('(')
      ..write(map((def) =>
          describeEnum(def.type.toString()) +
          (def.name?.value != null ? ' "${def.name!.value}"' : '')).join(', '))
      ..write(')');

    return sb.toString();
  }
}

/// Strips the type name from an enum value's toString.
String describeEnum(String enumString) {
  return enumString.substring(enumString.indexOf('.') + 1);
}
