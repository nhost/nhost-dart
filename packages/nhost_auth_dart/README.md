# Nhost Functions Dart SDK

[![Pub](https://img.shields.io/pub/v/nhost_dart)](https://pub.dev/packages/nhost_dart)
[![nhost_dart tests](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml)

[Nhost](https://nhost.io) Functions API for Dart

## Getting Started

Get your subdomain and region from nhost dashboard

```dart
import 'package:nhost_auth_dart/nhost_auth_dart.dart';

void main() async {
  // Setup
  final auth = NhostAuthClient(url: authUrl);

  try {
    await auth.signInEmailPassword(
      email: 'user-1@nhost.io',
      password: 'password-1',
    );
    // Print out a few details about the current user
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      print('currentUser.id: ${currentUser.id}');
      print('currentUser.displayName: ${currentUser.displayName}');
      print('currentUser.email: ${currentUser.email}');
      // And logout
      await auth.signOut();
    }
  } catch (e) {
    print(e);
  }

  // Release
  auth.close();
}

```

### Latest Release

```yaml
dependencies:
  nhost_auth_dart: ^2.0.0
```
