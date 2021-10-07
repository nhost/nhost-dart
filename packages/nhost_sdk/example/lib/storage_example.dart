import 'package:nhost_sdk/nhost_sdk.dart';

import 'auth_example.dart';

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';

void main() async {
  // Setup
  final client = NhostClient(baseUrl: nhostApiUrl);
  await loginOrRegister(client,
      email: 'user-1@nhost.io', password: 'password-1');

  final fileName = 'some_text_file.txt';
  final userPath = '/user/${client.auth.currentUser!.id}/';
  final filePath = '$userPath$fileName';

  // Create a new file...
  final fileMetadata = await client.storage.uploadString(
    filePath: filePath,
    string: 'abcdef abcdef abcdef abcdef abcdef',
    contentType: 'text/plain',
  );

  // ...turn around and download its contents...
  final downloadedFileContent = await client.storage
      .downloadFile(filePath, fileToken: fileMetadata.nhostMetadata!.token);
  print('Downloaded file contents:');
  print(downloadedFileContent.body);

  // ...then delete it.
  await client.storage.delete(filePath);

  // Release
  client.close();
}
