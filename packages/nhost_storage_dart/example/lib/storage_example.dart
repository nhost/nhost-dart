import 'package:nhost_auth_dart/nhost_auth_dart.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';

import 'config.dart';

void main() async {
  // Setup
  final auth = AuthClient(
    subdomain: subdomain,
    region: region,
  );

  final storage = StorageClient(
    subdomain: subdomain,
    region: region,
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

  // Create a new file...
  final fileMetadata = await storage.uploadString(
    fileName: 'some_text_file.txt',
    fileContents: 'abcdef abcdef abcdef abcdef abcdef',
    mimeType: 'text/plain',
  );
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
