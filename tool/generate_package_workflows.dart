import 'dart:io';

const workflowTemplateFileName = 'test.{package}.yaml.template';
const packageNameTemplatePattern = '{#dart_package_name}';
final pathSeparator = Platform.pathSeparator;
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
      File(platformPath([workflowsDirectory.path, workflowTemplateFileName]));
  final workflowTemplateSrc = workflowTemplateFile.readAsStringSync();

  // Produce one workflow per package
  for (final entry in Directory(platformPath(['.', 'packages'])).listSync()) {
    if (entry is! Directory) continue;

    final packageName = basename(entry.path);

    final packageWorkflowPath =
        platformPath([workflowsDirectory.path, 'test.$packageName.yaml']);
    File(packageWorkflowPath)
      ..createSync()
      ..writeAsStringSync(workflowTemplateSrc.replaceAll(
          packageNameTemplatePattern, packageName));
  }
}

String platformPath(List<String> pathParts) =>
    pathParts.join(Platform.pathSeparator);

/// Ordinarily I'd depend on `path` to do this, but we're not in a package
/// so we can't have dependencies
String basename(String path) {
  final lastSeparatorIndex = path.lastIndexOf(pathSeparator);
  return lastSeparatorIndex != -1
      ? path.substring(path.lastIndexOf(pathSeparator) + 1)
      : path;
}
