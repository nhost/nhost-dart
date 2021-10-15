import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_sdk/src/foundation/collection.dart';
import 'package:nhost_sdk/src/foundation/uri.dart';
import 'package:path/path.dart' show Context, Style;
import 'package:test/test.dart';

import 'admin_gql.dart';
import 'matchers.dart';
import 'setup.dart';
import 'test_helpers.dart';

/// Used to join URL paths
final pathContext = Context(style: Style.url);

void main() async {
  final gqlAdmin = GqlAdminTestHelper(apiUrl: apiUrl, gqlUrl: gqlUrl);

  NhostClient client;
  late Storage storage;
  User? user;

  setUpAll(() => initializeHttpFixturesForSuite('storage'));

  setUp(() async {
    // Clear out any data from the previous test
    await gqlAdmin.clearUsers();

    // Get a recording/playback HTTP client from Betamax
    final httpClient = await setUpApiTest();

    // Create a fresh client
    client = createApiTestClient(httpClient);

    // Register the basic user
    await registerAndLoginBasicUser(client.auth);

    // Provide a few values to tests
    user = client.auth.currentUser;
    storage = client.storage;

    // Clear out all user files from previous run
    try {
      final userFiles =
          await storage.getDirectoryMetadata('/user/${user!.id}/');
      for (final file in userFiles) {
        await storage.delete(file.key);
      }
    } catch (_) {}
  });

  /// Returns [path] inside the user's storage directory.
  ///
  /// Note that this is configurable on the backend via storage rules.
  String pathInUserDirectory(path) => joinSubpath('user/${user!.id}', path);

  group('creating files', () {
    test('defaults to uploading application/octet-stream', () async {
      final fileMetadata = await storage.uploadString(
        filePath: pathInUserDirectory('/test-file.txt'),
        string: 'text file contents',
        // no contentType
      );
      expect(fileMetadata.contentType, applicationOctetStreamType);
    });

    test('can write strings', () async {
      final filePath = pathInUserDirectory('/test-file.txt');
      final fileContents = 'text file contents';
      final fileMetadata = await storage.uploadString(
        filePath: filePath,
        string: fileContents,
        contentType: 'text/plain',
      );

      // Verify metadata
      expect(fileMetadata.key, filePath);
      expect(fileMetadata.contentType, 'text/plain');

      // Verify stored media
      final storedFile = await storage.downloadFile(filePath);
      final storedFileMimeType =
          ContentType.parse(storedFile.headers[HttpHeaders.contentTypeHeader]!);
      expect(storedFileMimeType.mimeType, 'text/plain');
      expect(storedFile.body, fileContents);
    });

    test('can write bytes', () async {
      final filePath = pathInUserDirectory('/test-file.bin');
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
        filePath: filePath,
        bytes: fileContents,
        contentType: 'text/html',
      );

      // Verify metadata
      expect(fileMetadata.key, filePath);
      expect(fileMetadata.contentType, 'text/html');

      // Verify stored media
      final storedFile = await storage.downloadFile(filePath);
      final storedFileMimeType =
          ContentType.parse(storedFile.headers[HttpHeaders.contentTypeHeader]!);
      expect(storedFileMimeType.mimeType, 'text/html');
      expect(storedFile.bodyBytes, fileContents);
    });

    test('reports upload progress', () async {
      final filePath = pathInUserDirectory('/test-file.bin');
      final fileContents = List.filled(math.pow(2, 20) as int, 0x00);

      final uploadCallback = UploadProgressCallbackFunctionMock();
      await storage.uploadBytes(
        filePath: filePath,
        bytes: fileContents,
        contentType: 'text/html',
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
    late String filePath;
    final fileContents = '* { margin: 0; }';
    final fileContentType = 'text/css';

    setUp(() async {
      filePath = pathInUserDirectory('/styles.css');
      await storage.uploadString(
        filePath: filePath,
        string: fileContents,
        contentType: fileContentType,
      );
    });

    test('can be downloaded', () async {
      final storedFile = await storage.downloadFile(filePath);
      expect(storedFile.body, fileContents);
    });

    test('can be deleted', () async {
      // Completion indicates the file is present
      await expectLater(storage.downloadFile(filePath), completes);

      // Now delete the file
      await storage.delete(filePath);

      // And ensure it is no longer available
      await expectLater(storage.downloadFile(filePath), throwsA(anything));
    });

    group('metadata', () {
      test('is accessible by file path', () async {
        final metadata = await storage.getFileMetadata(filePath);
        expect(metadata.key, filePath);
        expect(metadata.contentType, fileContentType);
      });

      test('is accessible by directory path', () async {
        final dirMetadata = await storage
            .getDirectoryMetadata(pathContext.dirname(filePath) + '/');
        expect(dirMetadata, hasLength(1));
        final fileMetadata = dirMetadata.first;
        expect(fileMetadata.key, filePath);
        expect(fileMetadata.contentType, fileContentType);
      });
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
