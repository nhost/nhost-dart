import 'package:nhost_dart_sdk/client.dart';
import 'package:random_string/random_string.dart';

void main() async {
  final client = NhostClient(
    baseUrl: 'https://backend-5e69d1d7.nhost.app',
  );
  await client.auth.login(email: 'scott@madewithfelt.com', password: 'foofoo');

  final fileName = '${randomAlpha(10)}.txt';
  final filePath = '/public/$fileName';

  // Upload
  await client.storage.putFileFromString(
    filePath: filePath,
    data: 'abcdef abcdef abcdef abcdef abcdef',
    contentType: 'text/plain',
  );

  // Single file
  final fileMetadata = await client.storage.getFileMetadata(
    filePath,
  );
  print('Single File');
  print(fileMetadata.toJson());

  // Directory metadata
  final fileMetadatasInPublic = await client.storage.getDirectoryMetadata(
    '/public/',
  );
  print('\nDirectory');
  print(fileMetadatasInPublic.map((f) => f.toJson()));

  // File removal
  await client.storage.delete(filePath);
  print('\nFile removed...most likely. Let\'s check');

  // Check to make sure
  try {
    final deletedFileMetadata = await client.storage.getFileMetadata(
      filePath,
    );
    print(deletedFileMetadata);
  } on ApiException catch (e) {
    print('Success!! The file is gone.');
    print('We know because of this: $e');
  }

  // Release
  client.close();
}
