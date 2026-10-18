# Nhost Dart SDK

[![Pub](https://img.shields.io/pub/v/nhost_dart)](https://pub.dev/packages/nhost_dart)
[![nhost_dart tests](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml)

[Nhost](https://nhost.io) authentication and file storage API clients for Dart
and Flutter.

Includes support for:

- User sign in and registration, including multi-factor authentication
- Email and password changes, either directly or via email confirmation
- Storage and retrieval of arbitrary files
- Scaling and transformation of stored files
- GraphQL authentication, via
  [nhost_graphql_adapter](https://pub.dev/packages/nhost_graphql_adapter)

### Sample

```dart
import 'package:nhost_dart/nhost_dart.dart';

void main() async {
  final nhost = NhostClient(
    subdomain: Subdomain(
      region: 'eu-central-1',
      subdomain: 'backend-5e69d1d7',
    ),
  );

  // For self-hosted or local projects, use ServiceUrls instead.
  /*
  final nhost = NhostClient(
    serviceUrls: ServiceUrls(
      authUrl: 'http://localhost:1337/v1/auth',
      storageUrl: 'http://localhost:1337/v1/storage',
      functionsUrl: 'http://localhost:1337/v1/functions',
      graphqlUrl: 'http://localhost:1337/v1/graphql',
    ),
  );
  */

  // User registration
  final authResponse = await nhost.auth.signUp(
    email: 'new-user@gmail.com',
    password: 'password-1',
  );

  // Upload a file
  final currentUser = authResponse.user ?? nhost.auth.currentUser;
  await nhost.storage.uploadBytes(
    fileName: '/users/${currentUser!.id}/image.jpg',
    fileContents: [/* ... */],
    mimeType: 'image/jpeg',
  );

  // Log out
  await nhost.auth.signOut();

  // Release resources
  nhost.close();
}
```

## Getting Started

### Latest Release

```yaml
dependencies:
  nhost_dart: ^2.2.0
```

## 🔥 More Dart & Flutter packages from Nhost

- [nhost_graphql_adapter](https://pub.dev/packages/nhost_graphql_adapter)
- [nhost_flutter_graphql](https://pub.dev/packages/nhost_flutter_graphql)
- [nhost_flutter_auth](https://pub.dev/packages/nhost_flutter_auth)
