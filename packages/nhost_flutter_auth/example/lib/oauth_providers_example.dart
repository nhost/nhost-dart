/// This example demonstrates the ability to login using an OAuth 2.0 provider,
/// on Android and iOS.
///
/// This example depends on the `url_launcher` and `app_links` packages
/// (https://pub.dev/packages/flutter_appauth), and requires that you set up a
/// GitHub OAuth application using the instructions at
/// https://docs.nhost.io/auth/oauth-providers/github
///
/// Then, in your Nhost project's "Sign-In" settings, set the redirect URL to
/// `nhost://open.example.auth.app`.
library oauth_providers_example;

import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:app_links/app_links.dart';

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';

void main() async {
  runApp(OAuthExample());
}

class OAuthExample extends StatefulWidget {
  @override
  _OAuthExampleState createState() => _OAuthExampleState();
}

class _OAuthExampleState extends State<OAuthExample> {
  NhostClient nhostClient;
  AppLinks appLinks;

  @override
  void initState() {
    super.initState();

    // Create a new Nhost client using your project's backend URL.
    nhostClient = NhostClient(baseUrl: nhostApiUrl);

    appLinks = AppLinks(
      onAppLink: (uri) async {
        print('!!!!! $uri');
        await url_launcher.closeWebView();
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
      child: MaterialApp(
        title: 'Nhost.io OAuth Example',
        home: Scaffold(
          body: SafeArea(
            child: TextButton(
              onPressed: () async {
                await url_launcher.launch(
                  'https://backend-5e69d1d7.nhost.app/auth/providers/github/',
                  forceSafariVC: true,
                );
              },
              child: Text('Authenticate with GitHub'),
            ),
          ),
          // ExampleProtectedScreen(),
        ),
      ),
    );
  }
}
