import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/encryption_service.dart';
import '../core/walrus_storage_service.dart';
import '../core/sui_blockchain_service.dart';
import '../core/local_file_service.dart';
import '../core/config.dart';

/// Provider for encryption service
final encryptionServiceProvider = Provider((ref) => EncryptionService());

/// Provider for Walrus storage service (publisher & aggregator)
final walrusStorageProvider = Provider(
  (ref) => WalrusStorageService(
    publisherUrl: EnvironmentConfig.walrusUrl,
    aggregatorUrl: EnvironmentConfig.walrusUrl,
  ),
);

/// Provider for Sui blockchain service
final suiBlockchainProvider = Provider(
  (ref) => SuiBlockchainService(
    rpcUrl: EnvironmentConfig.suiRpc,
    packageId: EnvironmentConfig.packageId,
  ),
);

/// Provider for local file service
final localFileServiceProvider = Provider((ref) => LocalFileService());

/// State for file upload/download operations
class FileOperationState {
  final bool isLoading;
  final String? error;
  final double progress;

  const FileOperationState({
    this.isLoading = false,
    this.error,
    this.progress = 0.0,
  });

  FileOperationState copyWith({
    bool? isLoading,
    String? error,
    double? progress,
  }) =>
      FileOperationState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        progress: progress ?? this.progress,
      );
}

/// State notifier for file operations
class FileOperationNotifier extends StateNotifier<FileOperationState> {
  final EncryptionService encryptionService;
  final WalrusStorageService walrusStorage;
  final SuiBlockchainService suiBlockchain;
  final LocalFileService localFileService;

  FileOperationNotifier({
    required this.encryptionService,
    required this.walrusStorage,
    required this.suiBlockchain,
    required this.localFileService,
  }) : super(const FileOperationState());

  /// Upload flow for the new spec:
  /// 1. Read file
  /// 2. Encrypt locally (generates random key + nonce)
  /// 3. Upload ciphertext to Walrus (publisher)
  /// 4. Register DataRoom on Sui with blobId and receiver address
  /// Returns a map containing `txDigest`, `blobId`, and `keyHex` (shareable secret)
  Future<Map<String, String>> uploadFile({
    required String filePath,
    required String receiverAddress,
    required String walletAddress,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Read file
      final fileData = await localFileService.readFile(filePath);
      state = state.copyWith(progress: 0.15);

      // Encrypt locally (produces ciphertext + key + nonce + mac)
      final encrypted = await encryptionService.encryptFile(fileData);
      state = state.copyWith(progress: 0.35);

      // Generate content hash for integrity (optional)
      final contentHash = await EncryptionService.generateHash(fileData);
      state = state.copyWith(progress: 0.45);

      // Upload ciphertext to Walrus publisher
      final blobId = await walrusStorage.uploadToWalrus(encrypted.ciphertext);
      state = state.copyWith(progress: 0.75);

      // Register DataRoom on-chain
      final txDigest = await suiBlockchain.registerDataRoom(
        blobId: blobId,
        receiverAddress: receiverAddress,
        walletAddress: walletAddress,
      );

      state = state.copyWith(isLoading: false, progress: 1.0);

      // Convert key bytes to hex for easy sharing off-chain (QR/code)
      final keyHex = EncryptionService.keyBytesToHex(encrypted.keyBytes);

      return {
        'txDigest': txDigest,
        'blobId': blobId,
        'keyHex': keyHex,
        'nonce': base64Encode(Uint8List.fromList(encrypted.nonce)),
        'mac': base64Encode(Uint8List.fromList(encrypted.mac)),
      };
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Upload failed: $e');
      rethrow;
    }
  }

  /// Retrieve flow:
  /// 1. Fetch blobId from chain (verifies caller & timer)
  /// 2. Download ciphertext from Walrus aggregator
  /// 3. Decrypt using provided keyHex + nonce + mac (off-chain)
  Future<Uint8List> retrieveFile({
    required String dataRoomObjectId,
    required String keyHex,
    required String nonceBase64,
    required String macBase64,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get blobId from blockchain (this will check auth & expiration)
      final blobId = await suiBlockchain.fetchBlobIdFromChain(dataRoomObjectId);
      state = state.copyWith(progress: 0.25);

      // Download ciphertext from Walrus aggregator
      final encryptedBytes = await walrusStorage.downloadFromWalrus(blobId);
      state = state.copyWith(progress: 0.6);

      // Reconstruct EncryptedFile using provided off-chain metadata
      final keyBytes = EncryptionService.hexToKeyBytes(keyHex);
      final nonce = base64Decode(nonceBase64);
      final mac = base64Decode(macBase64);

      final encryptedFile = EncryptedFile(
        ciphertext: encryptedBytes,
        nonce: nonce,
        mac: mac,
        keyBytes: keyBytes,
      );

      // Decrypt
      final plaintext =
          await encryptionService.decryptFile(encryptedFile, keyBytes);
      state = state.copyWith(isLoading: false, progress: 1.0);

      return plaintext;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Retrieval failed: $e');
      rethrow;
    }
  }
}

/// Provider for file operations
final fileOperationProvider =
    StateNotifierProvider<FileOperationNotifier, FileOperationState>((ref) {
  return FileOperationNotifier(
    encryptionService: ref.watch(encryptionServiceProvider),
    walrusStorage: ref.watch(walrusStorageProvider),
    suiBlockchain: ref.watch(suiBlockchainProvider),
    localFileService: ref.watch(localFileServiceProvider),
  );
});
