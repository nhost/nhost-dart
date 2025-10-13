import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart';
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

    var httpClient = Client();

    // Create a fresh client
    client = createApiTestClient(httpClient);

    await gqlAdmin.clearUsers();

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
        mimeType: 'text/plain; charset=utf-8',
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
        onUploadProgress: uploadCallback.call,
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

    test('uploadFiles can upload single file', () async {
      final filePath = 'single-file.txt';
      final fileContents = 'single file contents';
      final fileData = FileData(
        Uint8List.fromList(fileContents.codeUnits),
        filename: filePath,
        contentType: 'text/plain',
      );

      final results = await storage.uploadFiles(files: [fileData]);

      expect(results.length, 1);
      expect(results[0].name, filePath);
      expect(results[0].mimeType, 'text/plain; charset=utf-8');

      // Verify stored media
      final storedFile = await gqlAdmin.getFileInfo(results[0].id);
      expect(storedFile!.name, filePath);
      expect(storedFile.mimeType, 'text/plain; charset=utf-8');
    });

    test('uploadFiles can upload multiple files', () async {
      final file1Contents = 'first file';
      final file2Contents = 'second file';

      final files = [
        FileData(
          Uint8List.fromList(file1Contents.codeUnits),
          filename: 'file1.txt',
          contentType: 'text/plain',
        ),
        FileData(
          Uint8List.fromList(file2Contents.codeUnits),
          filename: 'file2.txt',
          contentType: 'text/plain',
        ),
      ];

      final results = await storage.uploadFiles(files: files);

      expect(results.length, 2);
      expect(results[0].name, 'file1.txt');
      expect(results[1].name, 'file2.txt');

      // Verify both files were stored
      final storedFile1 = await gqlAdmin.getFileInfo(results[0].id);
      final storedFile2 = await gqlAdmin.getFileInfo(results[1].id);
      expect(storedFile1, isNotNull);
      expect(storedFile2, isNotNull);
    });

    test('uploadFiles can upload with custom metadata', () async {
      final fileContents = 'file with metadata';
      final fileData = FileData(
        Uint8List.fromList(fileContents.codeUnits),
        filename: 'metadata-file.txt',
        contentType: 'text/plain',
      );

      final metadata = UploadFileMetadata(
        id: 'custom-file-id',
        name: 'custom-name.txt',
        metadata: {'category': 'test', 'priority': 'high'},
      );

      final results = await storage.uploadFiles(
        files: [fileData],
        metadataList: [metadata],
      );

      expect(results.length, 1);
      expect(results[0].id, 'custom-file-id');
      expect(results[0].name, 'custom-name.txt');

      // Verify stored file
      final storedFile = await gqlAdmin.getFileInfo(results[0].id);
      expect(storedFile!.id, 'custom-file-id');
      expect(storedFile.name, 'custom-name.txt');
    });

    test('uploadFiles can upload multiple files with metadata', () async {
      final files = [
        FileData(
          Uint8List.fromList('first'.codeUnits),
          filename: 'file1.txt',
          contentType: 'text/plain',
        ),
        FileData(
          Uint8List.fromList('second'.codeUnits),
          filename: 'file2.txt',
          contentType: 'text/plain',
        ),
      ];

      final metadataList = [
        UploadFileMetadata(
          name: 'custom-file-1.txt',
          metadata: {'order': 1},
        ),
        UploadFileMetadata(
          name: 'custom-file-2.txt',
          metadata: {'order': 2},
        ),
      ];

      final results = await storage.uploadFiles(
        files: files,
        metadataList: metadataList,
      );

      expect(results.length, 2);
      expect(results[0].name, 'custom-file-1.txt');
      expect(results[1].name, 'custom-file-2.txt');

      // Verify both files were stored
      final storedFile1 = await gqlAdmin.getFileInfo(results[0].id);
      final storedFile2 = await gqlAdmin.getFileInfo(results[1].id);
      expect(storedFile1!.name, 'custom-file-1.txt');
      expect(storedFile2!.name, 'custom-file-2.txt');
    });

    test('uploadFiles respects bucketId', () async {
      final fileData = FileData(
        Uint8List.fromList('test'.codeUnits),
        filename: 'bucket-test.txt',
        contentType: 'text/plain',
      );

      final results = await storage.uploadFiles(
        files: [fileData],
        bucketId: 'default',
      );

      expect(results.length, 1);
      expect(results[0].bucketId, 'default');
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
