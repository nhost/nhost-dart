import 'dart:io';

import 'package:nhost_sdk/nhost_sdk.dart';

import 'auth_example.dart';

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';

void main() async {
  // Setup
  final client = NhostClient(baseUrl: nhostApiUrl);
  await loginOrRegister(client,
      email: 'user-1@nhost.io', password: 'password-1');

  final fileName = 'henry.jpg';
  final userPath = '/user/${client.auth.currentUser.id}/';
  final filePath = '$userPath$fileName';

  // Store a new image file...
  final originalImageBytes = File('./assets/henry.jpg').readAsBytesSync();
  final imageMetadata = await client.storage.uploadBytes(
    filePath: filePath,
    bytes: originalImageBytes,
    contentType: 'image/jpeg',
  );
  print('Uploaded image');
  print('Size: ${originalImageBytes.length}');

  // ...turn around and download its contents, scaled...
  final downloadedImage = await client.storage.downloadImage(
    filePath,
    fileToken: imageMetadata.nhostMetadata.token,
    imageTransformConfig: ImageTransformConfig(width: 100, quality: 50),
  );
  print('Downloaded transformed image');
  print('Size: ${downloadedImage.bodyBytes.length}');

  // ...then delete it.
  await client.storage.delete(filePath);

  // Release
  client.close();
}
