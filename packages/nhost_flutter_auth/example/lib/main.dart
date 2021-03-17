import 'package:flutter/material.dart';

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

class SimpleAuthenticationExample extends StatelessWidget {
  SimpleAuthenticationExample({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}
