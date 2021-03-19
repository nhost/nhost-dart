import 'dart:io';

import 'package:nock/nock.dart';
import 'package:test/test.dart';

void main() {
  group('http links', () {
    setUpAll(() {
      nock.init();
    });

    setUp(() {
      nock.cleanAll();
    });

    tearDownAll(() {
      HttpOverrides.global = null;
    });

    test('unauthenticated clients do not send auth headers', () {});
    test('authenticated clients send auth headers', () {});
    test('default headers are provided', () {
      (nock('').get('')..headers({})).reply(200, null);
    });
  });
}
