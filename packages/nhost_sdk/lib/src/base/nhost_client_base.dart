import 'package:http/http.dart' as http;

import '../api/service_urls.dart';
import '../api/subdomain.dart';
import './functions_client.dart';
import './hasura_auth_client.dart';
import './hasura_storage_client.dart';

abstract class NhostClientBase {
  NhostClientBase({
    this.serviceUrls,
    this.subdomain,
  });

  final Subdomain? subdomain;
  final ServiceUrls? serviceUrls;

  http.Client get httpClient;
  String get gqlEndpointUrl;
  HasuraAuthClient get auth;
  FunctionsClient get functions;
  HasuraStorageClient get storage;

  void close();
}
