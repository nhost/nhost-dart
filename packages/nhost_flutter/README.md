# Nhost for Flutter

[![Pub](https://img.shields.io/pub/v/nhost_flutter)](https://pub.dev/packages/nhost_flutter)
[![nhost_flutter tests](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_flutter.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_flutter.yaml)

All-in-one [Nhost](https://nhost.io) package for Flutter apps. Bundles auth,
storage, functions and GraphQL, and persists authentication tokens securely by
default.

Includes:

- `Nhost.initialize()` once in `main()`, then `Nhost.instance` anywhere
- Refresh tokens stored in the platform keychain via
  [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage),
  and a session restore on startup
- A sealed `AuthState` you can `switch` on exhaustively
- `authStateChanges` and `authStateListenable` on `NhostAuthClient`
- Auth widgets: `NhostAuthGate`, `NhostAuthStateBuilder`, `NhostSignedIn`,
  `NhostSignedOut`, `NhostUserBuilder`

### Sample

```dart
import 'package:flutter/material.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Nhost.initialize(
    subdomain: Subdomain(
      region: 'eu-central-1',
      subdomain: 'backend-5e69d1d7',
    ),
  );

  // For a project running via the Nhost CLI, use Nhost.local() instead.
  // await Nhost.local();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NhostAuthProvider(
      auth: Nhost.instance.auth,
      child: MaterialApp(
        home: NhostAuthGate(
          loading: (context) => const SplashScreen(),
          signedOut: (context) => const SignInScreen(),
          signedIn: (context, user, session) => HomeScreen(user: user),
        ),
      ),
    );
  }
}
```

Sign in and out through the client, and the widgets above rebuild:

```dart
await Nhost.instance.auth.signInEmailPassword(
  email: 'user@nhost.io',
  password: 'password-1',
);

await Nhost.instance.auth.signOut();
```

## Getting Started

### Latest Release

```yaml
dependencies:
  nhost_flutter: ^1.0.0
```

## 🔥 More Dart & Flutter packages from Nhost

- [nhost_dart](https://pub.dev/packages/nhost_dart)
- [nhost_flutter_auth](https://pub.dev/packages/nhost_flutter_auth)
- [nhost_flutter_graphql](https://pub.dev/packages/nhost_flutter_graphql)
- [nhost_graphql_adapter](https://pub.dev/packages/nhost_graphql_adapter)
