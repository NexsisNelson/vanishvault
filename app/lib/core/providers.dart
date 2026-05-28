import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/encryption_service.dart';
import '../core/walrus_storage_service.dart';
import '../core/sui_blockchain_service.dart';
import '../core/local_file_service.dart';

/// Provider for encryption service
final encryptionServiceProvider = Provider((ref) => EncryptionService());

/// Provider for Walrus storage service
final walrusStorageProvider = Provider(
  (ref) => WalrusStorageService(walrusUrl: 'https://walrus.mainnet.sui.io'),
);

/// Provider for Sui blockchain service
final suiBlockchainProvider = Provider(
  (ref) => SuiBlockchainService(
    rpcUrl: 'https://fullnode.mainnet.sui.io',
    packageId: 'YOUR_PACKAGE_ID_HERE', // Replace with actual package ID
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
  }) => FileOperationState(
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

  Future<String> uploadFile({
    required String filePath,
    required String passphrase,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Read file
      final fileData = await localFileService.readFile(filePath);
      state = state.copyWith(progress: 0.2);

      // Encrypt
      final encrypted = await encryptionService.encrypt(fileData, passphrase);
      state = state.copyWith(progress: 0.4);

      // Generate hash
      final contentHash = await EncryptionService.generateHash(fileData);
      state = state.copyWith(progress: 0.6);

      // Upload to Walrus
      final blobId = await walrusStorage.uploadFile(
        encrypted.ciphertext,
        filePath.split('/').last,
      );
      state = state.copyWith(progress: 0.8);

      // Record on Sui blockchain
      final txDigest = await suiBlockchain.uploadFileToContract(
        walrusPath: blobId,
        contentHash: contentHash,
        accessKey: encrypted.nonce,
      );
      state = state.copyWith(isLoading: false, progress: 1.0);

      return txDigest;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Upload failed: $e');
      rethrow;
    }
  }

  Future<Uint8List> retrieveFile({
    required String fileObjectId,
    required String blobId,
    required String passphrase,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Download from Walrus
      final encryptedData = await walrusStorage.downloadFile(blobId);
      state = state.copyWith(progress: 0.5);

      // Decrypt using passphrase
      final decrypted = await encryptionService.decrypt(
        EncryptedData.fromJson({
          'ciphertext': encryptedData,
          'nonce': [],
          'mac': [],
        }),
        passphrase,
      );
      state = state.copyWith(isLoading: false, progress: 1.0);

      return decrypted;
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
