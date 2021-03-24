import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart';

const workflowTemplateFileName = 'test.{package}.yaml.template';
final templateVarPattern = RegExp(r'#{(?<binding>[^}]+)}');
final packageWorkflowFileNamePattern = RegExp(r'^test.([a-zA-Z_\d]+).yaml$');

void main() {
  final workflowsDirectory = Directory('.github/workflows');

  // Clean out old workflows
  final existingWorkflowFiles = workflowsDirectory.listSync().where(
      (entry) => packageWorkflowFileNamePattern.hasMatch(basename(entry.path)));
  for (final workflowFile in existingWorkflowFiles) {
    workflowFile.deleteSync();
  }

  // Open up the template
  final workflowTemplateFile =
      File(join(workflowsDirectory.path, workflowTemplateFileName));
  final workflowTemplateSrc = workflowTemplateFile.readAsStringSync();

  // Produce one workflow per package
  for (final entry in Directory(join('.', 'packages')).listSync()) {
    if (entry is! Directory) continue;

    final packageName = basename(entry.path);

    // Produce variables for the template
    final templateVars = {
      'dart_package_name': packageName,
    };

    final envFile = File(join(workflowsDirectory.path, '$packageName.env'));
    if (envFile.existsSync()) {
      final envVars = Parser().parse(envFile.readAsLinesSync());

      templateVars['dart_package_workflow_env'] = '\n' +
          envVars.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
    } else {
      templateVars['dart_package_workflow_env'] = ' {}';
    }

    final workflowSrc = workflowTemplateSrc.replaceAllMapped(
      templateVarPattern,
      (match) {
        final regexpMatch = match as RegExpMatch;
        final binding = regexpMatch.namedGroup('binding');
        return templateVars[binding] ?? '';
      },
    );

    final workflowPath =
        join(workflowsDirectory.path, 'test.$packageName.yaml');
    File(workflowPath)
      ..createSync()
      ..writeAsStringSync(workflowSrc);
  }
}
