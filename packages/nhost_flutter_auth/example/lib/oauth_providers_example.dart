/// This example demonstrates the ability to login using an OAuth 2.0 provider,
/// on Android and iOS.
///
/// This example depends on the `url_launcher` and `app_links` packages
/// (https://pub.dev/packages/flutter_appauth), and requires that you set up a
/// GitHub OAuth application using the instructions at
/// https://docs.nhost.io/auth/oauth-providers/github
///
/// Then, in your Nhost project's "Sign-In" settings, set:
///
/// Success redirect URL: `nhost-example://oauth.login.success`.
/// Failure redirect URL: `nhost-example://oauth.login.failure`.
library oauth_providers_example;

import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:app_links/app_links.dart';

import 'simple_auth_example.dart';

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';
const nhostGithubLoginUrl = '$nhostApiUrl/auth/providers/github/';

const loginSuccessHost = 'oauth.login.success';
const loginFailureHost = 'oauth.login.failure';

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
      onAppLink: (uri, stringUri) async {
        if (uri.host == loginSuccessHost) {
          // ignore: unawaited_futures
          nhostClient.auth.completeOAuthProviderLogin(uri);
        }
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
            child: ExampleProtectedScreen(),
          ),
          // ExampleProtectedScreen(),
        ),
      ),
    );
  }
}

class ExampleProtectedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // NhostAuthProvider.of will register this widget so that it rebuilds
    // whenever the user's authentication state changes.
    final auth = NhostAuthProvider.of(context);
    Widget widget;

    switch (auth.authenticationState) {
      case AuthenticationState.loggedIn:
        widget = LoggedInUserDetails();
        break;
      default:
        widget = ProviderLoginForm();
        break;
    }

    return Padding(
      padding: EdgeInsets.all(32),
      child: widget,
    );
  }
}

class ProviderLoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          await url_launcher.launch(
            nhostGithubLoginUrl,
            forceSafariVC: true,
          );
        } on Exception {
          // Exceptions can occur due to weirdness with redirects
        }
      },
      child: Text('Authenticate with GitHub'),
    );
  }
}
