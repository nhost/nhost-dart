import 'package:nhost_sdk/nhost_sdk.dart';

import 'config.dart';

void main() async {
  final functions = NhostClient(backendUrl: nhostUrl).functions;

  print('Running serverless function /hello');
  final helloResponse =
      await functions.callFunction('/hello', query: {'name': 'Universe'});
  print('Response: ${helloResponse.body}');
}
