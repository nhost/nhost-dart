# Nhost Storage Dart SDK

[![Pub](https://img.shields.io/pub/v/nhost_dart)](https://pub.dev/packages/nhost_dart)
[![nhost_dart tests](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml)

[Nhost](https://nhost.io) Storage API for Dart

## Getting Started

Get your subdomain and region from nhost dashboard
User Authentication is needed in order to upload.

```dart
import 'package:nhost_auth_dart/nhost_auth_dart.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';

void main() async {
  // Setup
  final auth = AuthClient(
    subdomain: 'subdomain',
    region: 'region',
  );

  final storage = StorageClient(
    subdomain: 'subdomain',
    region: 'region',
    // this must be passed form Auth session otherwise,
    // the sessions are not shared and therefore, headers for API calls
    // will be missed.
    session: auth.userSession,
  );

  await auth.signInEmailPassword(email: 'user-1@nhost.io', password: 'password-1');

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

```

### Latest Release

```yaml
dependencies:
  nhost_auth_dart: ^4.0.0
  nhost_storage_dart: ^4.0.0
```
