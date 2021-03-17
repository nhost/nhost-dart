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
    // The NhostAuth widget provides authentication state to its subtree, which
    // can be accessed using NhostAuth.of(BuildContext).
    return NhostAuth(
      auth: nhostClient.auth,
      child: Screen(),
    );
  }
}

class Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // NhostAuth.of will register this widget so that it rebuilds whenever
    // the user's authentication state changes.
    final auth = NhostAuth.of(context);
    if (auth.isAuthenticated == true) {
      return ProtectedContent();
    } else {
      return LoginForm();
    }
  }
}

class ProtectedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = NhostAuth.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        children: [
          Text('Welcome to the protected content!', style: textTheme.headline3),
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
    final auth = NhostAuth.of(context);

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
    const spacing = SizedBox(height: 12);
    return Padding(
      padding: EdgeInsets.all(32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            spacing,
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            spacing,
            ElevatedButton(
              onPressed: tryLogin,
              child: Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}
