import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Handles file uploads and downloads with Walrus P2P storage
/// Uses the Walrus Publisher and Aggregator endpoints as per the spec
class WalrusStorageService {
  final Dio _dio;
  final Logger _logger;

  /// Walrus Publisher endpoint for uploads
  final String publisherUrl;

  /// Walrus Aggregator endpoint for downloads
  final String aggregatorUrl;

  WalrusStorageService({
    required this.publisherUrl,
    required this.aggregatorUrl,
    Logger? logger,
  }) : _logger = logger ?? Logger(),
       _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(minutes: 5),
         ),
       );

  /// Upload encrypted file to Walrus using the Publisher endpoint
  /// Takes encrypted blob and returns a Walrus blob ID (hex string)
  ///
  /// Endpoint: PUT /v1
  /// Returns: { "blobId": "0x..." }
  Future<String> uploadToWalrus(Uint8List encryptedData) async {
    try {
      _logger.i('Uploading encrypted file to Walrus...');

      // Stream the encrypted bytes to the Walrus Publisher via PUT request
      final response = await _dio.put(
        '$publisherUrl/v1',
        data: Stream.fromIterable(encryptedData.map((e) => [e])),
        options: Options(
          contentType: 'application/octet-stream',
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract blob ID from response
        final blobId = response.data['blobId'] as String?;
        if (blobId == null) {
          throw Exception('No blobId in response');
        }

        _logger.i('File uploaded successfully. Blob ID: $blobId');
        return blobId;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('Walrus upload error: ${e.message}');
      throw Exception('Upload to Walrus failed: ${e.message}');
    } catch (e) {
      _logger.e('Failed to upload file: $e');
      rethrow;
    }
  }

  /// Download file from Walrus Aggregator using blob ID
  /// Takes the blob ID (hex string) and streams encrypted bytes back
  ///
  /// Endpoint: GET /v1/{blobId}
  /// Returns: Raw encrypted bytes
  Future<Uint8List> downloadFromWalrus(String blobId) async {
    try {
      _logger.i('Downloading encrypted file from Walrus aggregator...');

      // Hit the Walrus Aggregator endpoint
      final response = await _dio.get(
        '$aggregatorUrl/v1/$blobId',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final encryptedBytes = response.data as Uint8List;
        _logger.i('File downloaded. Size: ${encryptedBytes.length} bytes');
        return encryptedBytes;
      } else {
        throw Exception('Download failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('Walrus download error: ${e.message}');
      throw Exception('Download from Walrus failed: ${e.message}');
    } catch (e) {
      _logger.e('Failed to download file: $e');
      rethrow;
    }
  }

  /// Verify that a blob exists on Walrus
  Future<bool> verifyBlobExists(String blobId) async {
    try {
      final response = await _dio.head('$aggregatorUrl/v1/$blobId');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Failed to verify blob: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
