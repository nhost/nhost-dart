import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:nhost_flutter_auth_example/config.dart';
import 'package:nhost_flutter_auth_example/simple_auth_example.dart';

/// Fill in this value with the subdomain and region found on your Nhost project page.
final String _authEndpoint = createNhostServiceEndpoint(
  subdomain: subdomain,
  region: region,
  service: 'auth',
);

// Facebook
final String nhostFacebookOAuthUrl = '$_authEndpoint/signin/provider/facebook';

// Google
final String nhostGoogleOAuthUrl = '$_authEndpoint/signin/provider/google';

// Apple
final String nhostAppleOAuthUrl = '$_authEndpoint/signin/provider/apple';

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
        title: 'Nhost.io OAuth Webview Example',
        home: Scaffold(
          body: SafeArea(
            child: ExampleProtectedScreen(
              nhostClient: nhostClient,
            ),
          ),
        ),
      ),
    );
  }
}

class ExampleProtectedScreen extends StatelessWidget {
  const ExampleProtectedScreen({
    super.key,
    required this.nhostClient,
  });

  final NhostClient nhostClient;

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
        widget = ProviderSignInForm(nhostClient: nhostClient);
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: widget,
    );
  }
}

class ProviderSignInForm extends StatelessWidget {
  const ProviderSignInForm({
    super.key,
    required this.nhostClient,
  });

  final NhostClient nhostClient;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            final Uri? uri = await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => OAuthWebView(
                      initialUrl: Uri.parse(nhostFacebookOAuthUrl),
                      redirectUrl: 'https://yourdomain.com',
                    )));

            if (uri != null) {
              await nhostClient.auth.completeOAuthProviderSignIn(uri);
            }
          },
          child: const Text('Authenticate with Facebook'),
        ),
        TextButton(
          onPressed: () async {
            final Uri? uri = await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => OAuthWebView(
                      initialUrl: Uri.parse(nhostGoogleOAuthUrl),
                      redirectUrl: 'https://yourdomain.com',
                    )));

            if (uri != null) {
              await nhostClient.auth.completeOAuthProviderSignIn(uri);
            }
          },
          child: const Text('Authenticate with Google'),
        ),
        TextButton(
          onPressed: () async {
            final Uri? uri = await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => OAuthWebView(
                      initialUrl: Uri.parse(nhostAppleOAuthUrl),
                      redirectUrl: 'https://yourdomain.com',
                    )));

            if (uri != null) {
              await nhostClient.auth.completeOAuthProviderSignIn(uri);
            }
          },
          child: const Text('Authenticate with Apple'),
        )
      ],
    );
  }
}

class OAuthWebView extends StatefulWidget {
  const OAuthWebView({
    super.key,
    required this.redirectUrl,
    required this.initialUrl,
  });

  final String redirectUrl;
  final Uri initialUrl;

  @override
  State<OAuthWebView> createState() => _OAuthWebViewState();
}

class _OAuthWebViewState extends State<OAuthWebView> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text(
          'Authenticate',
        ),
        centerTitle: true,
        leading: CupertinoButton(
          onPressed: Navigator.of(context).pop,
          child: const Icon(
            Icons.arrow_back_ios,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          InAppWebView(
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                transparentBackground: true,
                useShouldOverrideUrlLoading: true,
                supportZoom: false,

                /// This custom userAgent is mandatory due to security constraints of Google's OAuth2 policies (https://developers.googleblog.com/2021/06/upcoming-security-changes-to-googles-oauth-2.0-authorization-endpoint.html)
                userAgent:
                    'Mozilla/5.0 Mobile AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15',
                preferredContentMode: UserPreferredContentMode.MOBILE,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              ),
            ),
            initialUrlRequest: URLRequest(
              url: widget.initialUrl,
            ),
            onReceivedServerTrustAuthRequest: (_, __) async {
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            shouldOverrideUrlLoading:
                (_, NavigationAction navigationAction) async {
              final Uri? url = navigationAction.request.url;
              final bool? isRedirect =
                  url?.toString().startsWith(widget.redirectUrl);
              if (isRedirect == true) {
                Navigator.pop(context, url);
              }

              return isRedirect != true
                  ? NavigationActionPolicy.ALLOW
                  : NavigationActionPolicy.CANCEL;
            },
            onLoadStop: (_, __) {
              setState(() {
                _isLoading = false;
              });
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
