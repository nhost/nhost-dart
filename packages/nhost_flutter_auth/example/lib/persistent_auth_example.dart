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

import 'simple_auth_example.dart';

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';

void main() {
  runApp(PersistentAuthExample());
}

class PersistentAuthExample extends StatefulWidget {
  @override
  _PersistentAuthExampleState createState() => _PersistentAuthExampleState();
}

class _PersistentAuthExampleState extends State<PersistentAuthExample> {
  NhostClient nhostClient;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's backend URL.
    nhostClient = NhostClient(
      baseUrl: nhostApiUrl,
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
  FutureOr<String> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  FutureOr<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  FutureOr<void> removeItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
