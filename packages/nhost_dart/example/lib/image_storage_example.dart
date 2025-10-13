import 'dart:io';

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

  // Upload a new image file using uploadFiles API...
  final imageData = FileData(
    File('./assets/henry.jpg').readAsBytesSync(),
    filename: 'henry.jpg',
    contentType: 'image/jpeg',
  );

  final uploadedImages = await client.storage.uploadFiles(files: [imageData]);
  final imageMetadata = uploadedImages.first;
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
