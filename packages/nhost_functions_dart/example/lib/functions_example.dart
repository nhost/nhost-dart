import 'package:nhost_functions_dart/nhost_functions_dart.dart';

import 'config.dart';

void main() async {
  final functions = FunctionsClient(
    subdomain: Subdomain(
      subdomain: subdomain,
      region: region,
    ),
  );

  print('Running serverless function /hello');
  final helloResponse = await functions.callFunction(
    '/hello',
    query: {'name': 'Universe'},
  );
  print('Response: ${helloResponse.body}');
}
