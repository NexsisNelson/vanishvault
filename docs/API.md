# VanishVault API Reference

## Overview

VanishVault exposes a Dart/Flutter API for local encryption, Walrus storage, and Sui blockchain interactions.

## Core Services

### EncryptionService

```dart
// Encrypt data
Future<EncryptedData> encrypt(Uint8List plaintext, String passphrase)

// Decrypt data
Future<Uint8List> decrypt(EncryptedData encryptedData, String passphrase)

// Generate content hash
Future<List<int>> generateHash(Uint8List data)
```

**Example:**
```dart
final service = EncryptionService();
final encrypted = await service.encrypt(fileData, 'my-passphrase');
final decrypted = await service.decrypt(encrypted, 'my-passphrase');
```

### WalrusStorageService

```dart
// Upload encrypted file
Future<String> uploadFile(Uint8List encryptedData, String filename)

// Download file
Future<Uint8List> downloadFile(String blobId)

// Verify file exists
Future<bool> verifyFileExists(String blobId)

// Get file metadata
Future<Map<String, dynamic>?> getFileMetadata(String blobId)

// Delete file
Future<bool> deleteFile(String blobId)

// Batch upload
Future<List<String>> uploadMultipleFiles(Map<String, Uint8List> files)
```

**Example:**
```dart
final service = WalrusStorageService(
  walrusUrl: 'https://walrus.mainnet.sui.io',
  publisherUrl: 'https://walrus.mainnet.sui.io',
  aggregatorUrl: 'https://walrus.mainnet.sui.io',
);
final blobId = await service.uploadFile(encryptedData, 'file.txt');
final downloaded = await service.downloadFile(blobId);
```

### SuiBlockchainService

```dart
// Connect wallet
Future<void> connectWallet()

// Upload file to contract
Future<String> uploadFileToContract({
  required String walrusPath,
  required List<int> contentHash,
  required List<int> accessKey,
  required String walletAddress,
})

// Get file metadata
Future<Map<String, dynamic>> getFileMetadata(String fileObjectId)

// Destroy file
Future<String> destroyFile(String fileObjectId)

// Check if can destroy
Future<bool> canDestroyFile(String fileObjectId)

// Get time until destruction
Future<Duration> getTimeUntilDestruction(String fileObjectId)
```

**Example:**
```dart
final service = SuiBlockchainService(
  rpcUrl: 'https://fullnode.mainnet.sui.io',
  packageId: '0x...package_id...',
);
final digest = await service.uploadFileToContract(
  walrusPath: blobId,
  contentHash: contentHash,
  accessKey: accessKey,
  walletAddress: walletAddress,
);
```

### LocalFileService

```dart
// Read file
Future<Uint8List> readFile(String filePath)

// Save encrypted file
Future<String> saveEncryptedFile(Uint8List encryptedData, String originalFileName)

// Delete file
Future<void> deleteFile(String filePath)

// Securely delete file
Future<void> secureDeleteFile(String filePath)

// List encrypted files
Future<List<String>> listEncryptedFiles()

// Get file size
Future<int> getFileSize(String filePath)

// Clear cache
Future<void> clearCache()
```

**Example:**
```dart
final service = LocalFileService();
final fileData = await service.readFile('/path/to/file.pdf');
final savedPath = await service.saveEncryptedFile(encryptedData, 'file.pdf');
```

## State Management (Riverpod)

### FileOperationNotifier

Manages file upload/download operations with progress tracking.

```dart
// Watch state
final state = ref.watch(fileOperationProvider);

// Upload file
await ref.read(fileOperationProvider.notifier).uploadFile(
  filePath: '/path/to/file',
  passphrase: 'strong-passphrase',
);

// Retrieve file
final decrypted = await ref.read(fileOperationProvider.notifier).retrieveFile(
  fileObjectId: '0x...',
  blobId: 'walrus_blob_id',
  passphrase: 'strong-passphrase',
);
```

**FileOperationState:**
```dart
class FileOperationState {
  final bool isLoading;      // Operation in progress
  final String? error;        // Error message if any
  final double progress;      // Progress 0.0-1.0
}
```

## Utility Functions

```dart
// Format bytes to human-readable
String formatBytes(int bytes)

// Format duration
String formatDuration(Duration duration)

// Validate passphrase
PassphraseStrength validatePassphrase(String passphrase)

// Bytes to Base64
String bytesToBase64(Uint8List bytes)

// Base64 to bytes
Uint8List base64ToBytes(String encoded)

// Truncate string
String truncate(String text, int maxLength)

// Generate random string
String generateRandomString(int length)
```

## Smart Contract Functions

### upload_file

```move
public fun upload_file(
    walrus_path: String,
    content_hash: vector<u8>,
    access_key: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) -> EncryptedFile
```

Uploads an encrypted file and sets destruction timer to 24 hours.

### retrieve_file

```move
public fun retrieve_file(
    file: &EncryptedFile,
    clock: &Clock,
    ctx: &TxContext,
) -> (String, vector<u8>)
```

Retrieves file access information if within 24-hour window and authorized.

### destroy_file

```move
public fun destroy_file(
    file: &mut EncryptedFile,
    clock: &Clock,
    ctx: &TxContext,
)
```

Forces file destruction after 24 hours. Emits event.

### get_file_info

```move
public fun get_file_info(file: &EncryptedFile) -> (address, u64, u64, bool)
```

Returns (owner, created_at, destruction_time, is_destroyed).

### can_destroy

```move
public fun can_destroy(file: &EncryptedFile, clock: &Clock) -> bool
```

Checks if file can be destroyed (24+ hours elapsed).

### time_until_destruction

```move
public fun time_until_destruction(file: &EncryptedFile, clock: &Clock) -> u64
```

Returns milliseconds until file destruction.

## Error Handling

```dart
try {
  final digest = await ref.read(fileOperationProvider.notifier).uploadFile(
    filePath: filePath,
    passphrase: passphrase,
  );
} catch (e) {
  print('Upload failed: $e');
}
```

Common errors:
- `FileSystemException`: File not found or permission denied
- `DioException`: Network error or Walrus connection failed
- `Exception`: Decryption failed (wrong passphrase)

---

**Last Updated**: May 2026
