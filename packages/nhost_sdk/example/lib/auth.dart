import 'dart:io';

import 'package:nhost_dart_sdk/client.dart';

void main() async {
  final client = NhostClient(
    baseUrl: 'https://backend-5e69d1d7.nhost.app',
  );
  stdout.write('\nLOGGING IN');
  waitForReturnKey();
  var response = await client.auth
      .login(email: 'scott@madewithfelt.com', password: 'foofoo');
  print('Success!');
  print('JWT:\n${response.session.jwtToken}');

  stdout.write('\nCHANGE PASS');
  waitForReturnKey();
  await client.auth
      .changePassword(oldPassword: 'foofoo', newPassword: 'foofoomcgoo');
  print('Success!');

  stdout.write('\nLOGOUT (so we can log back in with new pass)');
  waitForReturnKey();
  response = await client.auth.logout();
  print('Session is gone:\n${response.session}');

  stdout.write('\nLOG BACK IN');
  waitForReturnKey();
  response = await client.auth
      .login(email: 'scott@madewithfelt.com', password: 'foofoomcgoo');
  print('JWT:\n${response.session.jwtToken}');

  // Roll back password change
  await client.auth
      .changePassword(oldPassword: 'foofoomcgoo', newPassword: 'foofoo');

  stdout.write('\nREQUEST EMAIL CHANGE to scotty.hyndman@gmail.com');
  waitForReturnKey();
  await client.auth.requestEmailChange(newEmail: 'scotty.hyndman@gmail.com');

  print('Check email for ticket, and enter here:');
  final ticket = stdin.readLineSync().trim();

  stdout.write('CONFIRM EMAIL CHANGE\n');
  waitForReturnKey();
  await client.auth.confirmEmailChange(ticket: ticket);
  print('Confirmed! New email address!');
  waitForReturnKey();

  stdout.write('\nHas the local user updated?');
  waitForReturnKey();
  print('Nope :(');
  print('Current user email: ${client.auth.currentUser.email}');

  stdout.write('\nREFRESH SESSION');
  waitForReturnKey();
  await client.auth.refreshSession();

  stdout.write('\nAnd now?');
  waitForReturnKey();
  print('YES!');
  print('Current user email: ${client.auth.currentUser.email}');

  stdout.write('\nREGISTER');
  waitForReturnKey();
  await client.auth.register(
    email: 'henry@dogs.com',
    password: 'abcdefg',
    defaultRole: 'dog',
    allowedRoles: ['dog'],
  );
  print('Done! currentUser: ${client.auth.currentUser.toJson()}');

  // Release
  client.close();
}

void waitForReturnKey() {
  stdin.readLineSync();
}
