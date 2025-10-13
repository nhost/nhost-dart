/// This example demonstrates the ability to store authentication tokens between
/// restarts of your application, so that the user is logged in automatically.
///
/// This example depends on the `flutter_secure_storage` package, which is used to
/// implement the [SecureAuthStore] class.
///
/// To try it out, run the application, log in, then restart the app. You should
/// see the contents of [ExampleProtectedScreen] without having to log in a
/// second time.
library secure_persistent_auth_example;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'simple_auth_example.dart';

void main() {
  runApp(const SecurePersistentAuthExample());
}

class SecurePersistentAuthExample extends StatefulWidget {
  const SecurePersistentAuthExample({
    super.key,
  });

  @override
  SecurePersistentAuthExampleState createState() =>
      SecurePersistentAuthExampleState();
}

class SecurePersistentAuthExampleState
    extends State<SecurePersistentAuthExample> {
  late NhostClient nhostClient;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's subdomain and region.
    nhostClient = NhostClient(
      subdomain: Subdomain(
        subdomain: subdomain,
        region: region,
      ),
      // Instruct the client to store tokens using the `flutter_secure_storage`.
      authStore: const SecureAuthStore(),
    );
    // this will fetch refresh token and will sign user in!
    nhostClient.auth
        .signInWithStoredCredentials()
        .then((value) => null)
        .catchError(
      (e) {
        // ignore: avoid_print
        print(e);
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    nhostClient.close();
  }

  @override
  Widget build(BuildContext context) {
    return NhostAuthProvider(
      auth: nhostClient.auth,
      child: const MaterialApp(
        title: 'Nhost.io Secure Persistent Flutter Authentication Example',
        home: Scaffold(
          body: ExampleProtectedScreen(),
        ),
      ),
    );
  }
}

/// An Nhost [AuthStore] implementation backed by the `flutter_secure_storage`
/// plugin, so authentication information is retained between runs of the
/// application.
class SecureAuthStore implements AuthStore {
  const SecureAuthStore();

  @override
  Future<String?> getString(String key) {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    return storage.read(key: key);
  }

  @override
  Future<void> setString(String key, String value) {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> removeItem(String key) {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    return storage.delete(key: key);
  }
}
