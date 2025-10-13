import 'dart:typed_data';

import 'package:nhost_dart/nhost_dart.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';

import 'auth_example.dart';
import 'config.dart';

void main() async {
  // Setup
  final client = NhostClient(
    subdomain: Subdomain(
      subdomain: subdomain,
      region: region,
    ),
  );
  await signInOrSignUp(client,
      email: 'user-1@nhost.io', password: 'password-1');

  // Create a new file using the uploadFiles API...
  final fileContents = 'abcdef abcdef abcdef abcdef abcdef';
  final fileData = FileData(
    Uint8List.fromList(fileContents.codeUnits),
    filename: 'some_text_file.txt',
    contentType: 'text/plain',
  );

  final uploadedFiles = await client.storage.uploadFiles(files: [fileData]);
  final fileMetadata = uploadedFiles.first;
  print('File uploaded!');

  // ...turn around and download its contents...
  final downloadedFileContent =
      await client.storage.downloadFile(fileMetadata.id);
  print('Downloaded file contents:');
  print(downloadedFileContent.body);

  // ...then delete it.
  await client.storage.delete(fileMetadata.id);

  // Release
  client.close();
}
