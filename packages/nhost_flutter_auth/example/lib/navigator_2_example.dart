/// Demonstrates the use of Nhost Auth with a Navigator 2.0 application.
///
/// The core idea being demonstrated here is the protected route. We accomplish
/// this by configuring our [ExampleRouterDelegate] to operate on path objects
/// ([ExampleRoutePath]s) that can optionally implement a [ProtectedRoutePath]
/// interface.
///
/// When the router delegate is requested to navigate to a [ProtectedRoutePath],
/// it will first check to see if the user is authenticated. If they are,
/// navigation will proceed. If not, they will be forwarded to the sign in page,
/// where they can authenticate, and upon success proceed to their requested
/// route.
library simple_auth_example;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'simple_auth_example.dart';

void main() {
  configurePackages();
  runApp(const NavigatorExampleApp());
}

void configurePackages() {
  Provider.debugCheckInvalidValueType = null;
}

class NavigatorExampleApp extends StatefulWidget {
  const NavigatorExampleApp({super.key});

  @override
  NavigatorExampleAppState createState() => NavigatorExampleAppState();
}

class NavigatorExampleAppState extends State<NavigatorExampleApp> {
  late NhostClient nhostClient;
  late ExampleNavigator appState;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's subdomain and region.
    nhostClient = NhostClient(
      subdomain: subdomain,
      region: region,
    );
    appState = ExampleNavigator();
  }

  @override
  void dispose() {
    super.dispose();
    nhostClient.close();
  }

  @override
  Widget build(BuildContext context) {
    // The NhostAuthProvider widget provides authentication state to its
    // subtree, which can be accessed using NhostAuthProvider.of(BuildContext).
    //
    // This is created ABOVE the router, so the router can access authentication
    // state.
    return NhostAuthProvider(
      auth: nhostClient.auth,
      child: Provider<ExampleNavigator>.value(
        value: appState,
        // The router uses the authentication state to decide what can be shown
        // to users. See the `ExampleRouterDelegate` class for more information.
        child: MaterialApp.router(
          title: 'Nhost.io Simple Flutter Authentication',
          routerDelegate: ExampleRouterDelegate(appState),
          routeInformationParser: ExampleRouteInformationParser(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

/// Changes the currently visible page in the application.
///
/// Accessible via `Provider.of<ExampleNavigator>(context)`.
class ExampleNavigator extends ChangeNotifier {
  /// The route currently being requested by the application.
  ///
  /// NOTE: This may not be the route displayed, if the route requires
  /// authentication and the user is not authenticated. See
  /// [ExampleRouterDelegate.build] for implementation logic.
  ExampleRoutePath get requestedRoutePath => _requestedRoutePath;
  ExampleRoutePath _requestedRoutePath = HomeRoutePath();

  /// Called by the application to request a route change
  void requestRoutePath(ExampleRoutePath value) {
    _requestedRoutePath = value;
    notifyListeners();
  }
}

/// The router delegate is responsible for determining the current page stack,
/// based on [navigator] and the user's authentication state.
class ExampleRouterDelegate extends RouterDelegate<ExampleRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ExampleRoutePath> {
  ExampleRouterDelegate(this.navigator) {
    // If the app state changes, we notify the delegate's listeners to trigger
    // a rebuild.
    navigator.addListener(notifyListeners);
  }

  final ExampleNavigator navigator;

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  ExampleRoutePath get currentConfiguration => navigator.requestedRoutePath;

  @override
  Future<void> setNewRoutePath(ExampleRoutePath configuration) {
    navigator.requestRoutePath(configuration);
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    // Here we request the current Nhost authentication information, and see
    // whether it's sufficient to access the requested route path.
    //
    // In this case, if the requested route path implements `AuthRequiredPath`,
    // then it requires a logged-in Nhost user. If none exists, the user will
    // be shown the sign in page.
    final auth = NhostAuthProvider.of(context)!;
    final requestedRoutePath = navigator.requestedRoutePath;
    final isSignInPageRequested = requestedRoutePath is SignInRoutePath &&
        auth.authenticationState != AuthenticationState.signedIn;
    final needsSignIn = requestedRoutePath is ProtectedRoutePath &&
        auth.authenticationState != AuthenticationState.signedIn;

    return Navigator(
      key: navigatorKey,
      pages: [
        const MaterialPage(child: AppFrame(child: HomePage())),
        if (isSignInPageRequested || needsSignIn)
          const MaterialPage(child: AppFrame(child: SignInPage())),
        if (requestedRoutePath is AdminRoutePath && !needsSignIn)
          const MaterialPage(child: AppFrame(child: AdminPage())),
      ],
      onPopPage: (route, result) {
        navigator.requestRoutePath(HomeRoutePath());
        notifyListeners();
        return route.didPop(result);
      },
    );
  }
}

/// Maps between OS/web routes, and [ExampleRoutePath]s used by the application.
class ExampleRouteInformationParser
    extends RouteInformationParser<ExampleRoutePath> {
  @override
  Future<ExampleRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);

    if (uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == 'admin') {
        return AdminRoutePath();
      } else if (uri.pathSegments.first == 'signin') {
        return SignInRoutePath();
      } else {
        return HomeRoutePath();
      }
    } else {
      return HomeRoutePath();
    }
  }

  @override
  RouteInformation restoreRouteInformation(ExampleRoutePath configuration) {
    if (configuration is HomeRoutePath) {
      return const RouteInformation(location: '/');
    }
    if (configuration is AdminRoutePath) {
      return const RouteInformation(location: '/admin');
    }
    if (configuration is SignInRoutePath) {
      return const RouteInformation(location: '/signin');
    }

    throw ('Unsupported configuration');
  }
}

/// Used to identify pages in the application
abstract class ExampleRoutePath {}

/// A marker interface used to indicate that authentication is required
abstract class ProtectedRoutePath {}

/// The administrator home page's route.
///
/// Note that this implements the [ProtectedRoutePath] interface, which instructs
/// the [ExampleRouterDelegate] to require a logged in user.
class AdminRoutePath extends ExampleRoutePath implements ProtectedRoutePath {}

/// The home page's route, accessible to both admin and anonymous users
class HomeRoutePath extends ExampleRoutePath {}

/// The sign in page's route
class SignInRoutePath extends ExampleRoutePath {}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    final isAuthenticated =
        auth.authenticationState == AuthenticationState.signedIn;
    final navigator = Provider.of<ExampleNavigator>(context);

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentItem(
          child: Text('Home', style: textTheme.headlineSmall),
        ),
        ContentItem(
          child: Text(
            isAuthenticated == true ? '(Authenticated)' : '(Unauthenticated)',
            style: isAuthenticated
                ? textTheme.bodySmall!.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  )
                : textTheme.bodySmall!.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ),
        const ContentItem(child: Text('This content is visible to everyone.')),
        if (auth.authenticationState == AuthenticationState.signedIn)
          const ContentItem(
            child: Text(
              'This additional content is only visible to authenticated '
              'users',
            ),
          ),
        ContentItem(
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  navigator.requestRoutePath(AdminRoutePath());
                },
                child: const Text('Admin Page (Protected)'),
              ),
              const SizedBox(width: 8),
              if (auth.authenticationState == AuthenticationState.signedOut)
                ElevatedButton(
                  onPressed: () {
                    navigator.requestRoutePath(SignInRoutePath());
                  },
                  child: const Text('Sign In'),
                ),
              if (auth.authenticationState == AuthenticationState.signedIn)
                ElevatedButton(
                  onPressed: () {
                    auth.signOut();
                  },
                  child: const Text('Logout'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Provider.of<ExampleNavigator>(context);

    return Column(
      children: [
        if (navigator.requestedRoutePath is ProtectedRoutePath)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[600]!),
              borderRadius: BorderRadius.circular(3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(top: 16),
            child: Text(
              'The requested page requires authentication',
              style: TextStyle(
                color: Colors.red[600],
                height: 1.05,
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: SignInForm(),
        ),
      ],
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentItem(
          child: Text(
            'You\'re on the Admin page!',
            style: textTheme.headlineSmall,
          ),
        ),
        const ContentItem(
          child: Text(
            'No one can see this unless they\'re authenticated.',
          ),
        ),
      ],
    );
  }
}

class AppFrame extends StatelessWidget {
  const AppFrame({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    final navigator = Provider.of<ExampleNavigator>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhost Navigator 2.0 Example'),
        actions: [
          if (auth.authenticationState == AuthenticationState.signedOut)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                navigator.requestRoutePath(SignInRoutePath());
              },
            ),
          if (auth.authenticationState == AuthenticationState.signedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                auth.signOut();
                navigator.requestRoutePath(HomeRoutePath());
              },
            ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: child,
      ),
    );
  }
}

class ContentItem extends StatelessWidget {
  const ContentItem({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }
}
