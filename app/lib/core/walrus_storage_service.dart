import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Handles file uploads and downloads with Walrus P2P storage.
/// Supports the documented Walrus API surface and keeps backward compatibility.
class WalrusStorageService {
  final Dio _dio;
  final Logger _logger;

  /// Base endpoint for Walrus storage.
  final String walrusUrl;

  /// Optional custom publisher endpoint.
  final String publisherUrl;

  /// Optional custom aggregator endpoint.
  final String aggregatorUrl;

  WalrusStorageService({
    required this.walrusUrl,
    String? publisherUrl,
    String? aggregatorUrl,
    Logger? logger,
  })  : publisherUrl = publisherUrl ?? walrusUrl,
        aggregatorUrl = aggregatorUrl ?? walrusUrl,
        _logger = logger ?? Logger(),
        _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 5),
          ),
        );

  String _buildUploadUrl([String? filename]) {
    if (filename == null || filename.isEmpty) {
      return '$publisherUrl/v1';
    }
    final encoded = Uri.encodeQueryComponent(filename);
    return '$publisherUrl/v1?filename=$encoded';
  }

  /// Upload encrypted file to Walrus using the Publisher endpoint.
  /// Returns a Walrus blob ID.
  Future<String> uploadToWalrus(
    Uint8List encryptedData, {
    String? filename,
  }) async {
    try {
      _logger.i('Uploading encrypted file to Walrus...');

      final response = await _dio.put(
        _buildUploadUrl(filename),
        data: encryptedData,
        options: Options(
          contentType: 'application/octet-stream',
          responseType: ResponseType.json,
          headers: filename != null && filename.isNotEmpty
              ? {'X-File-Name': filename}
              : null,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data as Map<String, dynamic>;
        final blobId = body['blobId'] as String? ??
            body['blob_id'] as String? ??
            body['id'] as String?;
        if (blobId == null) {
          throw Exception('No blobId in response');
        }

        _logger.i('File uploaded successfully. Blob ID: $blobId');
        return blobId;
      }
      throw Exception('Upload failed with status ${response.statusCode}');
    } on DioException catch (e) {
      _logger.e('Walrus upload error: ${e.message}');
      throw Exception('Upload to Walrus failed: ${e.message}');
    } catch (e) {
      _logger.e('Failed to upload file: $e');
      rethrow;
    }
  }

  /// Download file from Walrus using the blob ID.
  Future<Uint8List> downloadFromWalrus(String blobId) async {
    try {
      _logger.i('Downloading encrypted file from Walrus aggregator...');

      final response = await _dio.get(
        '$aggregatorUrl/v1/$blobId',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final encryptedBytes = data is Uint8List
            ? data
            : Uint8List.fromList(List<int>.from(data as List<int>));
        _logger.i('File downloaded. Size: ${encryptedBytes.length} bytes');
        return encryptedBytes;
      }
      throw Exception('Download failed with status ${response.statusCode}');
    } on DioException catch (e) {
      _logger.e('Walrus download error: ${e.message}');
      throw Exception('Download from Walrus failed: ${e.message}');
    } catch (e) {
      _logger.e('Failed to download file: $e');
      rethrow;
    }
  }

  /// Upload encrypted file to Walrus. Alias for uploadToWalrus.
  Future<String> uploadFile(Uint8List encryptedData, String filename) async {
    return uploadToWalrus(encryptedData, filename: filename);
  }

  /// Download encrypted file from Walrus. Alias for downloadFromWalrus.
  Future<Uint8List> downloadFile(String blobId) async {
    return downloadFromWalrus(blobId);
  }

  /// Verify that a blob exists on Walrus.
  Future<bool> verifyBlobExists(String blobId) async {
    try {
      final response = await _dio.head('$aggregatorUrl/v1/$blobId');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Failed to verify blob: $e');
      return false;
    }
  }

  /// Alias for verifyBlobExists to match Walrus API naming.
  Future<bool> verifyFileExists(String blobId) async {
    return verifyBlobExists(blobId);
  }

  /// Get metadata for a Walrus blob.
  Future<Map<String, dynamic>?> getFileMetadata(String blobId) async {
    try {
      final response = await _dio.get(
        '$aggregatorUrl/v1/$blobId/metadata',
        options: Options(responseType: ResponseType.json),
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      _logger.e('Failed to fetch metadata: ${e.message}');
      rethrow;
    }
  }

  /// Delete a Walrus blob.
  Future<bool> deleteFile(String blobId) async {
    try {
      final response = await _dio.delete('$aggregatorUrl/v1/$blobId');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      _logger.e('Failed to delete file: ${e.message}');
      return false;
    }
  }

  /// Upload multiple files to Walrus in parallel.
  Future<List<String>> uploadMultipleFiles(Map<String, Uint8List> files) async {
    final futures = files.entries
        .map((entry) => uploadFile(entry.value, entry.key))
        .toList();
    return await Future.wait(futures);
  }

  /// Dispose resources.
  void dispose() {
    _dio.close();
  }
}
