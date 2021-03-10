import 'package:nhost_dart_sdk/client.dart';

void main() async {
  final nhost = NhostClient(
    baseUrl: 'https://backend-5e69d1d7.nhost.app',
  );
  await nhost.auth.login(email: 'scott@madewithfelt.com', password: 'foofoo');
  await nhost.storage.getDirectoryMetadata('/public/');
}
