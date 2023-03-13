/// This example demonstrates the ability to sign in using an OAuth 2.0
/// provider, on Android and iOS.
///
/// This example depends on the `url_launcher` and `app_links` packages
/// (https://pub.dev/packages/flutter_appauth), and requires that you set up a
/// GitHub OAuth application.
///
/// Then, in your Nhost project's "Sign-In" settings, set:
///
/// Success redirect URL: `nhost-example://oauth.login.success`.
/// Failure redirect URL: `nhost-example://oauth.login.failure`.
library oauth_providers_example;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'config.dart';
import 'simple_auth_example.dart';

/// Fill in this value with the subdomain and region found on your Nhost project page.
final nhostGithubSignInUrl = '${createNhostServiceEndpoint(
  subdomain: subdomain,
  region: region,
  service: 'auth',
)}/signin/provider/github';

const signInSuccessHost = 'oauth.login.success';
const signInFailureHost = 'oauth.login.failure';

void main() async {
  runApp(const OAuthExample());
}

class OAuthExample extends StatefulWidget {
  const OAuthExample({super.key});

  @override
  OAuthExampleState createState() => OAuthExampleState();
}

class OAuthExampleState extends State<OAuthExample> {
  late NhostClient nhostClient;
  late AppLinks appLinks;

  handleAppLink() async {
    appLinks = AppLinks();
    final uri = await appLinks.getInitialAppLink();
    if (uri?.host == signInSuccessHost) {
      // ignore: unawaited_futures
      nhostClient.auth.completeOAuthProviderSignIn(uri!);
    }
    await url_launcher.closeInAppWebView();
  }

  @override
  void initState() {
    super.initState();

    // Create a new Nhost client using your project's subdomain and region.
    nhostClient = NhostClient(
      subdomain: Subdomain(
        subdomain: subdomain,
        region: region,
      ),
    );
    handleAppLink();
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
        title: 'Nhost.io OAuth Example',
        home: Scaffold(
          body: SafeArea(
            child: ExampleProtectedScreen(),
          ),
        ),
      ),
    );
  }
}

class ExampleProtectedScreen extends StatelessWidget {
  const ExampleProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // NhostAuthProvider.of will register this widget so that it rebuilds
    // whenever the user's authentication state changes.
    final auth = NhostAuthProvider.of(context)!;
    Widget widget;

    switch (auth.authenticationState) {
      case AuthenticationState.signedIn:
        widget = const LoggedInUserDetails();
        break;
      default:
        widget = const ProviderSignInForm();
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: widget,
    );
  }
}

class ProviderSignInForm extends StatelessWidget {
  const ProviderSignInForm({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          await url_launcher.launchUrl(
            Uri.parse(nhostGithubSignInUrl),
          );
        } on Exception {
          // Exceptions can occur due to weirdness with redirects
        }
      },
      child: const Text('Authenticate with GitHub'),
    );
  }
}
