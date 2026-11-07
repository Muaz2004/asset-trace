import 'dart:convert';
import 'dart:io';

import 'package:aau_pc_verify/core/constants/app_constants.dart';
import 'package:aau_pc_verify/features/registration/data/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_service_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StorageService - File validation', () {
    test('throws StorageException when file does not exist', () async {
      final service = StorageService();
      final nonExistentFile = File('${tempDir.path}/does_not_exist.jpg');

      expect(
        () => service.uploadRegistrationPhoto(
          file: nonExistentFile,
          registrationTempId: 'reg_123',
          photoType: 'pc_photo',
        ),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('does not exist'),
          ),
        ),
      );
    });

    test('throws StorageException when file is empty (0 bytes)', () async {
      final service = StorageService();
      final emptyFile = File('${tempDir.path}/empty.jpg');
      await emptyFile.writeAsBytes([]);

      expect(
        () => service.uploadRegistrationPhoto(
          file: emptyFile,
          registrationTempId: 'reg_123',
          photoType: 'pc_photo',
        ),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('empty (0 bytes)'),
          ),
        ),
      );
    });

    test('throws StorageException when file format is unsupported', () async {
      final service = StorageService();
      final textFile = File('${tempDir.path}/test.txt');
      await textFile.writeAsString('Not an image');

      expect(
        () => service.uploadRegistrationPhoto(
          file: textFile,
          registrationTempId: 'reg_123',
          photoType: 'pc_photo',
        ),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported image format'),
          ),
        ),
      );
    });
  });

  group('StorageService - Upload operations', () {
    test('successfully uploads photo and returns secure_url', () async {
      final dummyFile = File('${tempDir.path}/photo.jpg');
      await dummyFile.writeAsBytes(List.generate(100, (i) => i % 256));

      String? capturedPreset;
      String? capturedFolder;
      String? capturedPublicId;
      final progressValues = <double>[];

      final mockClient = MockClient.streaming((request, bodyStream) async {
        expect(request.url.toString(), AppConstants.cloudinaryUploadUrl);
        expect(request.method, 'POST');

        if (request is http.MultipartRequest) {
          capturedPreset = request.fields['upload_preset'];
          capturedFolder = request.fields['folder'];
          capturedPublicId = request.fields['public_id'];
          expect(request.files.length, 1);
          expect(request.files.first.field, 'file');
        }

        // Consume stream to simulate transmission
        await bodyStream.drain();

        final responseJson = jsonEncode({
          'secure_url': 'https://res.cloudinary.com/cyk4nxfd/image/upload/v12345/aau-pc-verify/test.jpg',
          'public_id': 'aau-pc-verify/test',
        });
        return http.StreamedResponse(
          Stream.value(utf8.encode(responseJson)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = StorageService(httpClient: mockClient);
      final url = await service.uploadRegistrationPhoto(
        file: dummyFile,
        registrationTempId: 'temp_456',
        photoType: 'pc_photo',
        onProgress: (p) => progressValues.add(p),
      );

      expect(url, 'https://res.cloudinary.com/cyk4nxfd/image/upload/v12345/aau-pc-verify/test.jpg');
      expect(capturedPreset, AppConstants.cloudinaryUploadPreset);
      expect(capturedFolder, AppConstants.cloudinaryFolder);
      expect(capturedPublicId, startsWith('temp_456_pc_photo_'));
      expect(progressValues.isNotEmpty, isTrue);
      expect(progressValues.last, 1.0);
    });

    test('throws StorageException on Cloudinary error response with message', () async {
      final dummyFile = File('${tempDir.path}/photo.png');
      await dummyFile.writeAsBytes(List.generate(50, (i) => i));

      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain();
        final errorJson = jsonEncode({
          'error': {'message': 'Upload preset not found'},
        });
        return http.StreamedResponse(
          Stream.value(utf8.encode(errorJson)),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = StorageService(httpClient: mockClient);

      expect(
        () => service.uploadRegistrationPhoto(
          file: dummyFile,
          registrationTempId: 'temp_789',
          photoType: 'student_pc_photo',
        ),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('Upload preset not found'),
          ),
        ),
      );
    });

    test('throws StorageException on Cloudinary response missing secure_url', () async {
      final dummyFile = File('${tempDir.path}/photo.jpg');
      await dummyFile.writeAsBytes(List.generate(50, (i) => i));

      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain();
        final responseJson = jsonEncode({'other_key': 'no_url'});
        return http.StreamedResponse(
          Stream.value(utf8.encode(responseJson)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = StorageService(httpClient: mockClient);

      expect(
        () => service.uploadRegistrationPhoto(
          file: dummyFile,
          registrationTempId: 'temp_789',
          photoType: 'pc_photo',
        ),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('no secure URL was returned'),
          ),
        ),
      );
    });

    test('deletePhotoByUrl executes safely without exception', () async {
      final service = StorageService();
      await expectLater(
        service.deletePhotoByUrl('https://res.cloudinary.com/dummy.jpg'),
        completes,
      );
    });
  });
}
