import 'dart:math' as math;

import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:nhost_dart/nhost_dart.dart';
import 'package:nhost_sdk/src/foundation/collection.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';
import 'package:test/test.dart';

import 'admin_gql.dart';
import 'matchers.dart';
import 'setup.dart';
import 'test_helpers.dart';

var testEmail = getTestEmail();
const testPassword = 'password-1';

void main() async {
  final gqlAdmin = GqlAdminTestHelper(
    subdomain: subdomain,
    region: region,
    gqlUrl: gqlUrl,
  );

  NhostClient client;
  late NhostStorageClient storage;

  setUpAll(() {
    initLogging();
  });

  tearDownAll(() async {
    await gqlAdmin.clearUsers();
  });

  setUp(() async {
    // Clear out all user files from previous run
    await gqlAdmin.clearFiles();

    var httpClient = http.Client();

    // Create a fresh client
    client = createApiTestClient(httpClient);

    // Register the basic user
    await registerAndSignInBasicUser(client.auth, testEmail, testPassword);

    // Provide a few values to tests
    storage = client.storage;
  });

  group('creating files', () {
    test('defaults to uploading application/octet-stream', () async {
      final fileMetadata = await storage.uploadString(
        fileName: '/test-file.txt',
        fileContents: 'text file contents',
        // no mimeType
      );
      expect(fileMetadata.mimeType, applicationOctetStreamType);
    });

    test('can write strings', () async {
      final filePath = 'test-file.txt';
      final fileContents = 'text file contents';
      final fileMetadata = await storage.uploadString(
        fileName: filePath,
        fileContents: fileContents,
        mimeType: 'text/plain',
      );

      // Verify metadata
      expect(fileMetadata.name, filePath);
      expect(fileMetadata.mimeType, 'text/plain; charset=utf-8');

      // Verify stored media

      final storedFile = await gqlAdmin.getFileInfo(fileMetadata.id);
      expect(storedFile!.name, filePath);
      expect(storedFile.mimeType, 'text/plain; charset=utf-8');
    });

    test('can write bytes', () async {
      final filePath = 'test-file.bin';
      final fileContents = [
        0x74,
        0x68,
        0x69,
        0x73,
        0x20,
        0x69,
        0x73,
        0x20,
        0x61,
        0x20,
        0x74,
        0x65,
        0x73,
        0x74,
        0x20,
        0x66,
        0x69,
        0x6c,
        0x65
      ];
      final fileMetadata = await storage.uploadBytes(
        fileName: filePath,
        fileContents: fileContents,
        mimeType: 'text/html',
      );

      // Verify metadata
      expect(fileMetadata.name, filePath);
      expect(fileMetadata.mimeType, 'text/html');

      // Verify stored media
      final storedFile = await gqlAdmin.getFileInfo(fileMetadata.id);
      expect(storedFile!.name, filePath);
      expect(storedFile.mimeType, 'text/html');
    });

    test('reports upload progress', () async {
      final filePath = 'test-file.bin';
      final fileContents = List.filled(math.pow(2, 20) as int, 0x00);

      final uploadCallback = UploadProgressCallbackFunctionMock();
      await storage.uploadBytes(
        fileName: filePath,
        fileContents: fileContents,
        mimeType: 'text/html',
        onUploadProgress: uploadCallback,
      );

      final verificationResult =
          verify(uploadCallback(captureAny, captureAny, captureAny));
      final progressCallArgs =
          chunkList(verificationResult.captured, 3).toList();

      final firstRequest = progressCallArgs[0][0];
      final firstTotalBytes = progressCallArgs[0][2] as int;

      // Verify consistent request arg
      expect(progressCallArgs.map((args) => args[0]),
          everyElement(equals(firstRequest)));

      // Verify consistent totalBytes arg
      expect(progressCallArgs.map((args) => args[2]),
          everyElement(equals(firstTotalBytes)));

      // Verify increasing uploadedBytes
      expect(progressCallArgs.map((args) => args[1]), isIncreasing);
    });
  });

  group('stored files', () {
    late String fileId;
    final fileContents = '* { margin: 0; }';
    final fileContentType = 'text/css';

    setUp(() async {
      final filePath = 'styles.css';
      final fileMd = await storage.uploadString(
        fileName: filePath,
        fileContents: fileContents,
        mimeType: fileContentType,
      );
      fileId = fileMd.id;
    });

    test('can be deleted', () async {
      // Sanity check
      expect(await gqlAdmin.getFileInfo(fileId), isNotNull);

      // Now delete the file
      await storage.delete(fileId);

      // And ensure it is no longer available
      expect(await gqlAdmin.getFileInfo(fileId), isNull);
    });
  });
}

abstract class UploadProgressCallbackFunction {
  void call(http.BaseRequest request, int bytesUploaded, int bytesTotal);
}

class UploadProgressCallbackFunctionMock extends Mock
    implements UploadProgressCallbackFunction {
  @override
  void call([http.BaseRequest? request, int? bytesUploaded, int? bytesTotal]) {
    super.noSuchMethod(
        Invocation.method(#call, [request, bytesUploaded, bytesTotal]));
  }
}
