import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Handles file uploads and downloads with Walrus P2P storage
class WalrusStorageService {
  final Dio _dio;
  final Logger _logger;
  final String walrusUrl;

  WalrusStorageService({required this.walrusUrl, Logger? logger})
    : _logger = logger ?? Logger(),
      _dio = Dio(
        BaseOptions(
          baseUrl: walrusUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

  /// Upload encrypted file to Walrus
  /// Returns the Walrus blob ID for retrieval
  Future<String> uploadFile(Uint8List encryptedData, String filename) async {
    try {
      _logger.i('Uploading file to Walrus: $filename');

      // Create multipart form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(encryptedData, filename: filename),
      });

      // Upload to Walrus
      final response = await _dio.post('/upload', data: formData);

      if (response.statusCode == 200) {
        final blobId = response.data['blobId'] as String;
        _logger.i('File uploaded successfully. Blob ID: $blobId');
        return blobId;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to upload file: $e');
      rethrow;
    }
  }

  /// Download file from Walrus using blob ID
  Future<Uint8List> downloadFile(String blobId) async {
    try {
      _logger.i('Downloading file from Walrus: $blobId');

      final response = await _dio.get(
        '/blob/$blobId',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        _logger.i('File downloaded successfully');
        return Uint8List.fromList(response.data);
      } else {
        throw Exception('Download failed with status ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to download file: $e');
      rethrow;
    }
  }

  /// Verify file integrity on Walrus
  Future<bool> verifyFileExists(String blobId) async {
    try {
      final response = await _dio.head('/blob/$blobId');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Failed to verify file: $e');
      return false;
    }
  }

  /// Get file metadata from Walrus
  Future<Map<String, dynamic>?> getFileMetadata(String blobId) async {
    try {
      final response = await _dio.get('/blob/$blobId/metadata');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to get metadata: $e');
      return null;
    }
  }

  /// Batch upload multiple files
  Future<List<String>> uploadMultipleFiles(Map<String, Uint8List> files) async {
    final blobIds = <String>[];

    for (final entry in files.entries) {
      try {
        final blobId = await uploadFile(entry.value, entry.key);
        blobIds.add(blobId);
      } catch (e) {
        _logger.w('Failed to upload ${entry.key}: $e');
      }
    }

    return blobIds;
  }

  /// Delete file from Walrus (if supported)
  Future<bool> deleteFile(String blobId) async {
    try {
      final response = await _dio.delete('/blob/$blobId');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Failed to delete file: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
