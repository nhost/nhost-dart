
import 'package:nhost_dart_sdk/nhost_dart_sdk.dart';

void main() async {
  final client = NhostClient(
    baseUrl: 'https://backend-5e69d1d7.nhost.app',
  );
  final authRes = await client.auth.login(email: 'scott@madewithfelt.com', password: 'foofoo');
  print(authRes);

  // // final another = await client.auth.mfaTotp(code: '574781', ticket: authRes.mfa.ticket);
  // // print(client.auth.isAuthenticated);
  // // await client.auth.disableMfa(code: '574781');
  // // await client.auth.enableMfa('633669');
  // final mfaResponse = await client.auth.generateMfa();
  // File('./qr.png').writeAsBytesSync(mfaResponse.qrCode.contentAsBytes());
}
