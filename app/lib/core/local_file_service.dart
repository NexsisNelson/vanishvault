import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// Handles local file management and encryption
class LocalFileService {
  final Logger _logger;

  LocalFileService({Logger? logger}) : _logger = logger ?? Logger();

  /// Read file from device storage
  Future<Uint8List> readFile(String filePath) async {
    try {
      _logger.i('Reading file: $filePath');
      final file = File(filePath);

      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final bytes = await file.readAsBytes();
      _logger.i('File read successfully. Size: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      _logger.e('Failed to read file: $e');
      rethrow;
    }
  }

  /// Save encrypted file to app storage
  Future<String> saveEncryptedFile(
    Uint8List encryptedData,
    String originalFileName,
  ) async {
    try {
      _logger.i('Saving encrypted file: $originalFileName');

      final appDir = await getApplicationDocumentsDirectory();
      final encryptedDir = Directory('${appDir.path}/encrypted');

      if (!await encryptedDir.exists()) {
        await encryptedDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final encryptedFileName = '${timestamp}_$originalFileName.encrypted';
      final filePath = '${encryptedDir.path}/$encryptedFileName';

      final file = File(filePath);
      await file.writeAsBytes(encryptedData);

      _logger.i('Encrypted file saved: $filePath');
      return filePath;
    } catch (e) {
      _logger.e('Failed to save encrypted file: $e');
      rethrow;
    }
  }

  /// Delete file from device storage
  Future<void> deleteFile(String filePath) async {
    try {
      _logger.i('Deleting file: $filePath');
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        _logger.i('File deleted successfully');
      } else {
        _logger.w('File not found: $filePath');
      }
    } catch (e) {
      _logger.e('Failed to delete file: $e');
      rethrow;
    }
  }

  /// Securely delete file (overwrite before deletion)
  Future<void> secureDeleteFile(String filePath) async {
    try {
      _logger.i('Securely deleting file: $filePath');
      final file = File(filePath);

      if (await file.exists()) {
        // Overwrite with random data
        final fileSize = await file.length();
        final randomData = _generateRandomBytes(fileSize);
        await file.writeAsBytes(randomData);

        // Delete file
        await file.delete();
        _logger.i('File securely deleted');
      }
    } catch (e) {
      _logger.e('Failed to securely delete file: $e');
      rethrow;
    }
  }

  /// List all encrypted files in app storage
  Future<List<String>> listEncryptedFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final encryptedDir = Directory('${appDir.path}/encrypted');

      if (!await encryptedDir.exists()) {
        return [];
      }

      final files = encryptedDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .toList();

      _logger.i('Found ${files.length} encrypted files');
      return files;
    } catch (e) {
      _logger.e('Failed to list files: $e');
      rethrow;
    }
  }

  /// Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      _logger.e('Failed to get file size: $e');
      rethrow;
    }
  }

  /// Generate random bytes for secure deletion
  Uint8List _generateRandomBytes(int length) {
    final random = <int>[];
    for (int i = 0; i < length; i++) {
      random.add((DateTime.now().microsecond % 256).toUnsigned(8));
    }
    return Uint8List.fromList(random);
  }

  /// Clear app cache and temporary files
  Future<void> clearCache() async {
    try {
      _logger.i('Clearing cache...');
      final tempDir = await getTemporaryDirectory();

      if (await tempDir.exists()) {
        tempDir.deleteSync(recursive: true);
      }

      _logger.i('Cache cleared');
    } catch (e) {
      _logger.e('Failed to clear cache: $e');
      rethrow;
    }
  }
}
