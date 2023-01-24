import 'package:nhost_dart/nhost_dart.dart';

import 'config.dart';

void main() async {
  final functions = NhostClient(
    subdomain: subdomain,
    region: region,
  ).functions;

  print('Running serverless function /hello');
  final helloResponse = await functions.callFunction(
    '/hello',
    query: {'name': 'Universe'},
  );
  print('Response: ${helloResponse.body}');
}
