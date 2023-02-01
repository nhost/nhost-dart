# Nhost Functions Dart SDK

[![Pub](https://img.shields.io/pub/v/nhost_dart)](https://pub.dev/packages/nhost_dart)
[![nhost_dart tests](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml)

[Nhost](https://nhost.io) Functions API for Dart

## Getting Started

Get your subdomain and region from nhost dashboard

```dart
import 'package:nhost_functions_dart/nhost_functions_dart.dart';

void main() async {
    final functions = NhostFunctionsClient(url: 'Your Service URL');

  print('Running serverless function /hello');
  final helloResponse = await functions.callFunction(
    '/hello',
    query: {'name': 'Universe'},
  );
  print('Response: ${helloResponse.body}');
}

```

### Latest Release

```yaml
dependencies:
  nhost_functions_dart: ^4.0.0
```
