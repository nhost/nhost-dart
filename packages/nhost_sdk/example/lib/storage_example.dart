import 'package:nhost_dart_sdk/client.dart';
import 'package:random_string/random_string.dart';

void main() async {
  final client = NhostClient(
    baseUrl: 'https://backend-5e69d1d7.nhost.app',
  );
  await client.auth.login(email: 'scott@madewithfelt.com', password: 'foofoo');

  final fileName = 'some_text_file.txt';
  final userPath = '/user/${client.auth.currentUser.id}/';
  final filePath = '$userPath$fileName';

  // Create a new file
  final fileMetadata = await client.storage.uploadString(
    filePath: filePath,
    string: 'abcdef abcdef abcdef abcdef abcdef',
    contentType: 'text/plain',
  );

  // Request its metadata again...
  final refreshedFileMetadata = await client.storage
      .getFileMetadata(filePath, fileToken: fileMetadata.nhostMetadata.token);
  print('File meta:');
  print(refreshedFileMetadata.toJson());

  // ...and its contents
  final downloadedFileContent = await client.storage
      .downloadFile(filePath, fileToken: fileMetadata.nhostMetadata.token);
  print('Downloaded file contents:');
  print(downloadedFileContent.body);

  // File removal
  await client.storage.delete(filePath);
  print('\nFile removed...most likely. Let\'s check');

  // Release
  client.close();
}
