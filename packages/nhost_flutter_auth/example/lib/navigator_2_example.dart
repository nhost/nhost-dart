/// Demonstrates the use of Nhost Auth with a Navigator 2.0 application.
library simple_auth_example;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:nhost_flutter_auth_sample/simple_auth_example.dart';
import 'package:provider/provider.dart';

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';

void main() {
  configurePackages();
  runApp(NavigatorExampleApp());
}

void configurePackages() {
  Provider.debugCheckInvalidValueType = null;
}

class NavigatorExampleApp extends StatefulWidget {
  @override
  _NavigatorExampleAppState createState() => _NavigatorExampleAppState();
}

class _NavigatorExampleAppState extends State<NavigatorExampleApp> {
  NhostClient nhostClient;
  ExampleNavigator appState;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's backend URL.
    nhostClient = NhostClient(baseUrl: nhostApiUrl);
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

///
class ExampleNavigator extends ChangeNotifier {
  /// The route currently being requested by the application.
  ///
  /// NOTE: This may not be the route displayed, if the route requires
  /// authentication and the user is not authenticated. See
  /// [ExampleRouterDelegate.build] for implementation logic.
  ExampleRoutePath get requestedRoutePath => _requestedRoutePath;
  ExampleRoutePath _requestedRoutePath;

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
  Future<void> setNewRoutePath(ExampleRoutePath routePath) {
    navigator.requestRoutePath(routePath);
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    // Here we request the current Nhost authentication information, and see
    // whether it's sufficient to access the requested route path.
    //
    // In this case, if the requested route path implements `AuthRequiredPath`,
    // then it requires a logged-in Nhost user. If none exists, the user will
    // be shown the login page.
    final auth = NhostAuthProvider.of(context);
    final requestedRoutePath = navigator.requestedRoutePath;
    final isLoginPageRequested =
        requestedRoutePath is LoginRoutePath && auth.isAuthenticated != true;
    final needsLogin =
        requestedRoutePath is AuthRequiredPath && auth.isAuthenticated != true;

    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(child: AppFrame(child: HomePage())),
        if (isLoginPageRequested || needsLogin)
          MaterialPage(child: AppFrame(child: LoginPage())),
        if (requestedRoutePath is AdminRoutePath && !needsLogin)
          MaterialPage(child: AppFrame(child: AdminPage())),
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
    final uri = Uri.parse(routeInformation.location);

    if (uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == 'admin') {
        return AdminRoutePath();
      } else if (uri.pathSegments.first == 'login') {
        return LoginRoutePath();
      }
    } else {
      return HomeRoutePath();
    }

    return null;
  }

  @override
  RouteInformation restoreRouteInformation(ExampleRoutePath configuration) {
    if (configuration is HomeRoutePath) {
      return RouteInformation(location: '/');
    }
    if (configuration is AdminRoutePath) {
      return RouteInformation(location: '/admin');
    }
    if (configuration is LoginRoutePath) {
      return RouteInformation(location: '/login');
    }
    return null;
  }
}

/// Used to identify pages in the application
abstract class ExampleRoutePath {}

/// A marker interface used to indicate that authentication is required
abstract class AuthRequiredPath {}

/// The administrator home page's route.
///
/// Note that this implements the [AuthRequiredPath] interface, which instructs
/// the [ExampleRouterDelegate] to require a logged in user.
class AdminRoutePath extends ExampleRoutePath implements AuthRequiredPath {}

/// The home page's route, accessible to both admin and anonymous users
class HomeRoutePath extends ExampleRoutePath {}

/// The login page's route
class LoginRoutePath extends ExampleRoutePath {}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context);
    final isAuthenticated = auth.isAuthenticated == true;
    final navigator = Provider.of<ExampleNavigator>(context);

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentItem(
          child: Text('Home', style: textTheme.headline5),
        ),
        ContentItem(
          child: Text(
            isAuthenticated == true ? '(Authenticated)' : '(Unauthenticated)',
            style: isAuthenticated
                ? textTheme.caption.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  )
                : textTheme.caption.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ),
        ContentItem(child: Text('This content is visible to everyone.')),
        if (auth.isAuthenticated == true)
          ContentItem(
            child: Text(
              'This additional content is only visible to authenticated '
              'users',
            ),
          ),
        ContentItem(
          child: Row(children: [
            ElevatedButton(
              onPressed: () {
                navigator.requestRoutePath(AdminRoutePath());
              },
              child: Text('Admin Page (Protected)'),
            ),
            SizedBox(width: 8),
            if (auth.isAuthenticated != true)
              ElevatedButton(
                onPressed: () {
                  navigator.requestRoutePath(LoginRoutePath());
                },
                child: Text('Login'),
              ),
            if (auth.isAuthenticated == true)
              ElevatedButton(
                onPressed: () {
                  auth.logout();
                },
                child: Text('Logout'),
              ),
          ]),
        ),
      ],
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navigator = Provider.of<ExampleNavigator>(context);

    return Container(
      child: Column(
        children: [
          if (navigator.requestedRoutePath is AuthRequiredPath)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red[600]),
                borderRadius: BorderRadius.circular(3),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: EdgeInsets.only(top: 16),
              child: Text(
                'The requested page requires authentication',
                style: TextStyle(
                  color: Colors.red[600],
                  height: 1.05,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: LoginForm(),
          ),
        ],
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentItem(
          child: Text('You\'re on the Admin page!', style: textTheme.headline5),
        ),
        ContentItem(
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
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context);
    final navigator = Provider.of<ExampleNavigator>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nhost Navigator 2.0 Example'),
        actions: [
          if (auth.isAuthenticated != true)
            IconButton(
              icon: Icon(Icons.login),
              onPressed: () {
                navigator.requestRoutePath(LoginRoutePath());
              },
            ),
          if (auth.isAuthenticated == true)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                auth.logout();
                navigator.requestRoutePath(HomeRoutePath());
              },
            ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: child,
      ),
    );
  }
}

class ContentItem extends StatelessWidget {
  const ContentItem({Key key, this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: child,
    );
  }
}
