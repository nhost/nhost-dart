/// Demonstrates sign in, logout, and requiring authentication to access a
/// resource.
library simple_auth_example;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

import 'config.dart';

void main() {
  runApp(SimpleAuthExample());
}

class SimpleAuthExample extends StatefulWidget {
  @override
  _SimpleAuthExampleState createState() => _SimpleAuthExampleState();
}

class _SimpleAuthExampleState extends State<SimpleAuthExample> {
  late NhostClient nhostClient;

  @override
  void initState() {
    super.initState();
    // Create a new Nhost client using your project's backend URL.
    nhostClient = NhostClient(backendUrl: nhostUrl);
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
    return NhostAuthProvider(
      auth: nhostClient.auth,
      child: MaterialApp(
        title: 'Nhost.io Simple Flutter Authentication',
        home: Scaffold(
          body: ExampleProtectedScreen(),
        ),
      ),
    );
  }
}

class ExampleProtectedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // NhostAuthProvider.of will register this widget so that it rebuilds whenever
    // the user's authentication state changes.
    final auth = NhostAuthProvider.of(context)!;
    Widget widget;
    switch (auth.authenticationState) {
      case AuthenticationState.signedIn:
        widget = LoggedInUserDetails();
        break;
      case AuthenticationState.signedOut:
        widget = SignInForm();
        break;
      default:
        widget = SizedBox();
        break;
    }

    return Padding(
      padding: EdgeInsets.all(32),
      child: widget,
    );
  }
}

const rowSpacing = SizedBox(height: 12);

class SignInForm extends StatefulWidget {
  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: 'user-1@nhost.io');
    passwordController = TextEditingController(text: 'password-1');
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void trySignIn() async {
    final auth = NhostAuthProvider.of(context)!;

    try {
      await auth.signInEmailPassword(
          email: emailController.text, password: passwordController.text);
    } on ApiException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in Failed'),
        ),
      );
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
              onFieldSubmitted: (_) => trySignIn(),
            ),
            rowSpacing,
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onFieldSubmitted: (_) => trySignIn(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: trySignIn,
              child: Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}

class LoggedInUserDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    final currentUser = auth.currentUser!;

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
              auth.signOut();
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
