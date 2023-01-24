import 'dart:io';

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

  // Upload a new image file...
  final imageMetadata = await client.storage.uploadBytes(
    fileName: 'henry.jpg',
    fileContents: File('./assets/henry.jpg').readAsBytesSync(),
    mimeType: 'image/jpeg',
  );
  print('Uploaded image');
  print('Size: ${imageMetadata.size}');

  // ...then download it, applying a transformation...
  final scaledImage = await client.storage.downloadImage(
    imageMetadata.id,
    transform: ImageTransform(
      width: 100,
      quality: 70,
      cornerRadius: ImageCornerRadius.full(),
    ),
  );
  print('Downloaded transformed image');
  print('Size: ${scaledImage.contentLength}');

  // ...then delete it.
  await client.storage.delete(imageMetadata.id);

  // Release
  client.close();
}
