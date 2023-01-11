/// This example demonstrates the ability to store authentication tokens between
/// restarts of your application, so that the user is logged in automatically.
///
/// This example depends on the `shared_preferences` package, which is used to
/// implement the [SharedPreferencesAuthStore] class.
///
/// To try it out, run the application, log in, then restart the app. You should
/// see the contents of [ExampleProtectedScreen] without having to log in a
/// second time.
library persistent_auth_example;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'simple_auth_example.dart';

void main() {
  runApp(const PersistentAuthExample());
}

class PersistentAuthExample extends StatefulWidget {
  const PersistentAuthExample({
    super.key,
  });

  @override
  PersistentAuthExampleState createState() => PersistentAuthExampleState();
}

class PersistentAuthExampleState extends State<PersistentAuthExample> {
  late NhostClient nhostClient;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's subdomain and region.
    nhostClient = NhostClient(
      subdomain: subdomain,
      region: region,
      // Instruct the client to store tokens using shared preferences.
      authStore: SharedPreferencesAuthStore(),
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
        title: 'Nhost.io Persistent Flutter Authentication Example',
        home: Scaffold(
          body: ExampleProtectedScreen(),
        ),
      ),
    );
  }
}

/// An Nhost [AuthStore] implementation backed by the `shared_preferences`
/// plugin, so authentication information is retained between runs of the
/// application.
class SharedPreferencesAuthStore implements AuthStore {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> removeItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
