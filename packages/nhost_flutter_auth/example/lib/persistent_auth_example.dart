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
  runApp(PersistentAuthExample());
}

class PersistentAuthExample extends StatefulWidget {
  @override
  _PersistentAuthExampleState createState() => _PersistentAuthExampleState();
}

class _PersistentAuthExampleState extends State<PersistentAuthExample> {
  late NhostClient nhostClient;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's backend URL.
    nhostClient = NhostClient(
      backendUrl: nhostUrl,
      // Instruct the client to store tokens using shared preferences.
      authStore: SharedPreferencesAuthStore(),
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
      child: MaterialApp(
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
