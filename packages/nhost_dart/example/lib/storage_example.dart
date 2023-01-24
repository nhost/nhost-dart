import 'package:nhost_dart/nhost_dart.dart';

import 'auth_example.dart';
import 'config.dart';

void main() async {
  // Setup
  final client = NhostClient(
    subdomain: subdomain,
    region: region,
  );
  await signInOrSignUp(client,
      email: 'user-1@nhost.io', password: 'password-1');

  // Create a new file...
  final fileMetadata = await client.storage.uploadString(
    fileName: 'some_text_file.txt',
    fileContents: 'abcdef abcdef abcdef abcdef abcdef',
    mimeType: 'text/plain',
  );
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
