import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';

/// Custom domain exception for image storage operations.
class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Service managing image uploads to Cloudinary using HTTPS unsigned presets.
class StorageService {
  StorageService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Maximum file size allowed: 10 MB (images are pre-compressed by image_picker to ~150-300 KB).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image file extensions.
  static const Set<String> allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
  };

  /// Uploads an image file directly to Cloudinary using HTTPS unsigned upload.
  ///
  /// Returns the confirmed [secure_url] emitted by Cloudinary.
  /// Reports upload progress to [onProgress] where supported.
  Future<String> uploadRegistrationPhoto({
    required File file,
    required String registrationTempId,
    required String photoType, // e.g. 'pc_photo' or 'student_pc_photo'
    void Function(double progress)? onProgress,
  }) async {
    // 1. File existence validation
    if (!file.existsSync()) {
      throw const StorageException('Selected image file does not exist on device.');
    }

    // 2. File size validation
    final int fileSize = file.lengthSync();
    if (fileSize == 0) {
      throw const StorageException('Selected image file is empty (0 bytes).');
    }
    if (fileSize > maxFileSizeBytes) {
      throw const StorageException(
        'Image file exceeds the 10 MB limit. Please select a smaller image.',
      );
    }

    // 3. Format validation
    final filePath = file.path;
    final dotIndex = filePath.lastIndexOf('.');
    final extension = dotIndex != -1 ? filePath.substring(dotIndex).toLowerCase() : '';
    if (!allowedExtensions.contains(extension)) {
      throw StorageException(
        'Unsupported image format "$extension". Allowed formats: JPG, JPEG, PNG, WEBP.',
      );
    }

    onProgress?.call(0.05);

    try {
      final uri = Uri.parse(AppConstants.cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // Cloudinary unsigned upload parameters
      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      request.fields['folder'] = AppConstants.cloudinaryFolder;
      request.fields['public_id'] =
          '${registrationTempId}_${photoType}_${DateTime.now().millisecondsSinceEpoch}';

      // Read file bytes with progress tracking
      int bytesSent = 0;
      final fileStream = file.openRead().transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            if (fileSize > 0 && onProgress != null) {
              final progress = 0.05 + (bytesSent / fileSize) * 0.90;
              onProgress(progress.clamp(0.05, 0.95));
            }
            sink.add(data);
          },
        ),
      );

      final fileName = filePath.split(Platform.pathSeparator).last;
      request.files.add(
        http.MultipartFile(
          'file',
          fileStream,
          fileSize,
          filename: fileName,
        ),
      );

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw const StorageException(
            'Upload timed out. Please check your internet connectivity and try again.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          throw const StorageException(
            'Invalid response format received from Cloudinary image storage.',
          );
        }

        final secureUrl = responseData['secure_url'] as String?;
        if (secureUrl == null || secureUrl.trim().isEmpty) {
          throw const StorageException(
            'Cloudinary upload succeeded but no secure URL was returned.',
          );
        }

        onProgress?.call(1.0);
        return secureUrl;
      } else {
        String? errorMessage;
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorJson['error']?['message'] as String?;
        } catch (_) {
          // Response body was not JSON
        }

        throw StorageException(
          errorMessage != null && errorMessage.isNotEmpty
              ? 'Cloudinary upload error: $errorMessage'
              : 'Cloudinary upload failed with HTTP status ${response.statusCode}.',
        );
      }
    } on SocketException {
      throw const StorageException(
        'Network error: Unable to connect to Cloudinary. Please check your internet connection.',
      );
    } on http.ClientException {
      throw const StorageException(
        'Network connection interrupted during photo upload. Please try again.',
      );
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Failed to upload verification photo: $e');
    }
  }

  /// Attempts deletion of an uploaded photo by its URL.
  ///
  /// IMPORTANT ARCHITECTURAL NOTE:
  /// In accordance with Cloudinary client-side security policies, unsigned upload
  /// presets DO NOT permit asset deletion or modification without an API secret
  /// or a signed administrative signature.
  ///
  /// Embedding Cloudinary API secrets in the Flutter client APK is strictly
  /// prohibited for security reasons. Therefore, asset deletion cannot be performed
  /// directly from the client without a privileged backend service.
  ///
  /// This method safely no-ops to ensure that registration failure rollback
  /// does not crash or break the officer's error recovery workflow.
  Future<void> deletePhotoByUrl(String url) async {
    debugPrint(
      '[StorageService] Cloudinary unsigned mode does not support client-side asset deletion. URL: $url',
    );
    return;
  }
}

/// Provider for [StorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
