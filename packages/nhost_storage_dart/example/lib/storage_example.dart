import 'dart:typed_data';

import 'package:nhost_auth_dart/nhost_auth_dart.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';

import 'config.dart';

void main() async {
  // Setup
  final auth = NhostAuthClient(url: authUrl);

  final storage = NhostStorageClient(
    url: storageUrl,
    // this must be passed form Auth session otherwise,
    // the sessions are not shared and therefore, headers for API calls
    // will be missed.
    session: auth.userSession,
  );

  await signInOrSignUp(
    auth,
    email: 'user-1@nhost.io',
    password: 'password-1',
  );

  // Create a new file using uploadFiles API...
  final fileContents = 'abcdef abcdef abcdef abcdef abcdef';
  final fileData = FileData(
    Uint8List.fromList(fileContents.codeUnits),
    filename: 'some_text_file.txt',
    contentType: 'text/plain',
  );

  final uploadedFiles = await storage.uploadFiles(files: [fileData]);
  final fileMetadata = uploadedFiles.first;
  print('File uploaded!');

  // ...turn around and download its contents...
  final downloadedFileContent = await storage.downloadFile(fileMetadata.id);
  print('Downloaded file contents:');
  print(downloadedFileContent.body);

  // ...then delete it.
  await storage.delete(fileMetadata.id);

  // Release
  auth.close();
  storage.close();
}
