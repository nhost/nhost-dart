/// Generates package-specific workflows from a template.
///
/// The reason we want package-specific workflows at all is so we can
///
/// 1. Limit the workflow to only being triggered on changes to files on the
///    package's path, and that of its dependents
/// 2. Display a package-specific testing badge (at the time of writing, you
///    can't request badges for matrix configurations)
/// 3. Receive more granular notifications about failure.
///
/// Template file: `./github/workflows/test.{package}.yaml.template`
/// Template variables supplied to template:
///
/// - `#{dart_package_name}`: The name of the package
/// - `#{dart_package_workflow_env}`: An optional set of environment variables
///   that is made available to the workflow, taken from a file named
///   `.github/workflows/{dart_package_name}.env`.
///
/// Instantiations of the template are produced by the Melos `postbootstrap`
/// script which can be found in `melos.yaml`.
library generate_package_workflows;

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
      final envVars = DotEnv(includePlatformEnvironment: true)..load();

      templateVars['dart_package_workflow_env'] = '\n' +
          envVars.map.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
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
