import 'package:nhost_dart_sdk/nhost_dart_sdk.dart';

void main() async {
  final client = NhostClient(
    baseUrl: 'https://backend-5e69d1d7.nhost.app',
  );
  await client.auth.login(email: 'scott@madewithfelt.com', password: 'foofoo');

  // Upload
  await uploadString(client);

  // Directory metadata
  await listPublic(client);

  // Single file
  print((await showFileMetadata(client)).toJson());

  // Release
  client.close();

  // // final another = await client.auth.mfaTotp(code: '574781', ticket: authRes.mfa.ticket);
  // // print(client.auth.isAuthenticated);
  // // await client.auth.disableMfa(code: '574781');
  // // await client.auth.enableMfa('633669');
  // final mfaResponse = await client.auth.generateMfa();
  // File('./qr.png').writeAsBytesSync(mfaResponse.qrCode.contentAsBytes());
}

Future<void> uploadString(NhostClient client) async {
  await client.storage.putFileFromString(
    filePath: '/public/abcd.txt',
    data: 'abcdef abcdef abcdef abcdef abcdef',
    contentType: 'text/plain',
  );
}

Future<void> listPublic(NhostClient client) async {
  final dirMetadata = await client.storage.getDirectoryMetadata(
    '/public/',
  );
  print(dirMetadata.map((e) => e.toJson()));
}

Future<FileMetadata> showFileMetadata(NhostClient client) async {
  return await client.storage.getFileMetadata(
    '/public/abcd.txt',
  );
}
