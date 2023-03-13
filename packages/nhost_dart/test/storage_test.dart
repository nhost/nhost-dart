import 'dart:math' as math;

import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:nhost_dart/nhost_dart.dart';
import 'package:nhost_sdk/src/foundation/collection.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';
import 'package:path/path.dart' show Context, Style;
import 'package:test/test.dart';

import 'admin_gql.dart';
import 'matchers.dart';
import 'setup.dart';
import 'test_helpers.dart';

/// Used to join URL paths
final pathContext = Context(style: Style.url);

void main() async {
  final unrecordedGqlAdmin = GqlAdminTestHelper(
    subdomain: subdomain,
    region: region,
    gqlUrl: gqlUrl,
  );
  GqlAdminTestHelper? recordedGqlAdmin;

  NhostClient client;
  late NhostStorageClient storage;

  setUpAll(() {
    initLogging();
    initializeHttpFixturesForSuite('storage');
  });

  setUp(() async {
    // Clear out any data from the previous test
    await unrecordedGqlAdmin.clearUsers();

    // Clear out all user files from previous run
    await unrecordedGqlAdmin.clearFiles();

    // Get a recording/playback HTTP client from Betamax
    final httpClient = await setUpApiTest();

    // Create a fresh client
    client = createApiTestClient(httpClient);

    // Register the basic user
    await registerAndSignInBasicUser(client.auth);

    // Provide a few values to tests
    storage = client.storage;
    recordedGqlAdmin = GqlAdminTestHelper(
      subdomain: subdomain,
      region: region,
      gqlUrl: gqlUrl,
      httpClientOverride: httpClient,
    );
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
      expect(fileMetadata.mimeType, 'text/plain');

      // Verify stored media

      final storedFile = await recordedGqlAdmin!.getFileInfo(fileMetadata.id);
      expect(storedFile!.name, filePath);
      expect(storedFile.mimeType, 'text/plain');
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
      final storedFile = await recordedGqlAdmin!.getFileInfo(fileMetadata.id);
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
      expect(await recordedGqlAdmin!.getFileInfo(fileId), isNotNull);

      // Now delete the file
      await storage.delete(fileId);

      // And ensure it is no longer available
      expect(await recordedGqlAdmin!.getFileInfo(fileId), isNull);
    });
  });
}

abstract class UploadProgressCallbackFunction {
  void call(BaseRequest request, int bytesUploaded, int bytesTotal);
}

class UploadProgressCallbackFunctionMock extends Mock
    implements UploadProgressCallbackFunction {
  @override
  void call([BaseRequest? request, int? bytesUploaded, int? bytesTotal]) {
    super.noSuchMethod(
        Invocation.method(#call, [request, bytesUploaded, bytesTotal]));
  }
}
