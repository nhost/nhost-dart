# Nhost Dart SDK

[![Pub](https://img.shields.io/pub/v/nhost_sdk)](https://pub.dev/packages/nhost_sdk)
[![nhost_sdk tests](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_sdk.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_sdk.yaml)

[Nhost](https://nhost.io) authentication and file storage API clients for Dart
and Flutter.

Includes support for:

* User login and registration, including multi-factor authentication
* Email and password changes, either directly or via email confirmation
* Storage and retrieval of arbitrary files
* Scaling and transformation of stored files
* GraphQL authentication, via
  [nhost_graphql_adapter](https://pub.dev/packages/nhost_graphql_adapter)

### Sample
```dart
import 'package:nhost_sdk/nhost_sdk.dart';

void main() async {
  final nhost = NhostClient(baseUrl: 'https://backend-5e69d1d7.nhost.app');

  // User registration
  await nhost.auth.register(email: 'new-user@gmail.com', password: 'xxxxx');

  // Upload a file
  final currentUser = nhost.auth.currentUser;
  await nhost.storage.uploadBytes(
    filePath: '/users/${currentUser.id}/image.jpg',
    bytes: [/* ... */],
    contentType: 'image/jpeg',
  ),

  // Log out
  await nhost.auth.logout();
}
```

## Getting Started
### Latest Release

```yaml
dependencies:
  nhost_sdk: ^3.0.0-beta.0
```

## 🔥 More Dart & Flutter packages from Nhost

* [nhost_graphql_adapter](https://pub.dev/packages/nhost_graphql_adapter)
* [nhost_flutter_graphql](https://pub.dev/packages/nhost_flutter_graphql)
* [nhost_flutter_auth](https://pub.dev/packages/nhost_flutter_auth)
