/// Demonstrates sign in, logout, and requiring authentication to access a
/// resource.
library simple_auth_example;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';

import 'config.dart';

void main() {
  runApp(const SimpleAuthExample());
}

class SimpleAuthExample extends StatefulWidget {
  const SimpleAuthExample({super.key});

  @override
  SimpleAuthExampleState createState() => SimpleAuthExampleState();
}

class SimpleAuthExampleState extends State<SimpleAuthExample> {
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
    // The NhostAuthProvider widget provides authentication state to its
    // subtree, which can be accessed using NhostAuthProvider.of(BuildContext).
    return NhostAuthProvider(
      auth: nhostClient.auth,
      child: const MaterialApp(
        title: 'Nhost.io Simple Flutter Authentication',
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
  const ExampleProtectedScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // NhostAuthProvider.of will register this widget so that it rebuilds whenever
    // the user's authentication state changes.
    final auth = NhostAuthProvider.of(context)!;
    Widget widget;
    switch (auth.authenticationState) {
      case AuthenticationState.signedIn:
        widget = const LoggedInUserDetails();
        break;
      case AuthenticationState.signedOut:
        widget = const SignInForm();
        break;
      default:
        widget = const SizedBox();
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: widget,
    );
  }
}

const rowSpacing = SizedBox(height: 12);

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  SignInFormState createState() => SignInFormState();
}

class SignInFormState extends State<SignInForm> {
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
        email: emailController.text,
        password: passwordController.text,
      );
    } on ApiException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in Failed'),
        ),
      );
    } on SocketException catch (e) {
      // ignore: avoid_print
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (_) => trySignIn(),
            ),
            rowSpacing,
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onFieldSubmitted: (_) => trySignIn(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: trySignIn,
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}

class LoggedInUserDetails extends StatelessWidget {
  const LoggedInUserDetails({super.key});

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
            style: textTheme.headlineSmall,
          ),
          rowSpacing,
          Text('User details:', style: textTheme.bodySmall),
          rowSpacing,
          Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
