import 'package:flutter/material.dart';
import 'package:nhost_dart_sdk/client.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

// HOW TO RUN THIS APP:
//
// Check out README.md for instructions on how to get your backend set up to run
// this application.
//
// For more authentication examples, visit
// https://github.com/nhost/nhost-flutter-auth/example/lib

/// Fill in this value with the backend URL found on your Nhost project page.
const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhost.io Simple Flutter Authentication',
      home: Scaffold(
        body: SimpleAuthenticationExample(),
      ),
    );
  }
}

class SimpleAuthenticationExample extends StatefulWidget {
  SimpleAuthenticationExample({Key key}) : super(key: key);

  @override
  _SimpleAuthenticationExampleState createState() =>
      _SimpleAuthenticationExampleState();
}

class _SimpleAuthenticationExampleState
    extends State<SimpleAuthenticationExample> {
  NhostClient nhostClient;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's backend URL.
    nhostClient = NhostClient(baseUrl: nhostApiUrl);
  }

  @override
  void dispose() {
    super.dispose();
    nhostClient.close();
  }

  @override
  Widget build(BuildContext context) {
    // The NhostAuthProvider widget provides authentication state to its subtree, which
    // can be accessed using NhostAuthProvider.of(BuildContext).
    return NhostAuthProvider(
      auth: nhostClient.auth,
      child: Screen(),
    );
  }
}

class Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // NhostAuthProvider.of will register this widget so that it rebuilds whenever
    // the user's authentication state changes.
    final auth = NhostAuthProvider.of(context);
    if (auth.isAuthenticated == true) {
      return LoggedInUserDetails();
    } else {
      return LoginForm();
    }
  }
}

const rowSpacing = SizedBox(height: 12);

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final formKey = GlobalKey<FormState>();
  TextEditingController emailController;
  TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void tryLogin() async {
    final auth = NhostAuthProvider.of(context);

    try {
      await auth.login(
          email: emailController.text, password: passwordController.text);
    } on ApiException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Form(
        key: formKey,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => tryLogin(),
              ),
              rowSpacing,
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onFieldSubmitted: (_) => tryLogin(),
              ),
              rowSpacing,
              ElevatedButton(
                onPressed: tryLogin,
                child: Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class LoggedInUserDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context);
    final currentUser = auth.currentUser;

    final textTheme = Theme.of(context).textTheme;
    const cellPadding = EdgeInsets.all(4);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome ${currentUser.email}!',
            style: textTheme.headline5,
          ),
          rowSpacing,
          Text('User details:', style: textTheme.caption),
          rowSpacing,
          Table(
            defaultColumnWidth: IntrinsicColumnWidth(),
            children: [
              for (final row in currentUser.toJson().entries)
                TableRow(
                  children: [
                    Padding(
                      padding: cellPadding.copyWith(right: 12),
                      child: Text(row.key),
                    ),
                    Padding(
                      padding: cellPadding,
                      child: Text('${row.value}'),
                    ),
                  ],
                )
            ],
          ),
          rowSpacing,
          ElevatedButton(
            onPressed: () {
              auth.logout();
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
