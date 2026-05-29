import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Handles AES-256-GCM encryption for VanishVault
/// Generates fresh random keys and nonces for each encryption operation.
class EncryptionService {
  static final _algorithm = AesGcm.with256bits();

  /// Encrypts a file using AES-256-GCM
  /// Generates a brand-new random 256-bit key and 12-byte nonce
  /// Returns the encrypted data with metadata needed for decryption
  Future<EncryptedFile> encryptFile(Uint8List plaintext) async {
    // Generate a brand-new random 256-bit AES secret key
    final secretKey = await _algorithm.newSecretKey();

    // Generate a random 12-byte initialization vector (nonce)
    final nonce = Uint8List.fromList(_algorithm.newNonce());

    // Encrypt the plaintext using AES-256-GCM
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    // Extract raw key bytes for transmission (to be shared with receiver)
    final keyBytes = Uint8List.fromList(await secretKey.extractBytes());

    return EncryptedFile(
      ciphertext: Uint8List.fromList(secretBox.cipherText),
      nonce: nonce,
      mac: Uint8List.fromList(secretBox.mac.bytes),
      keyBytes: keyBytes,
    );
  }

  /// Decrypts a file using AES-256-GCM
  /// Requires the key and nonce that were generated during encryption
  Future<Uint8List> decryptFile(
    EncryptedFile encryptedFile,
    Uint8List keyBytes,
  ) async {
    // Reconstruct the SecretKey from the provided key bytes
    final secretKey = SecretKey(keyBytes);

    // Create SecretBox from encrypted data
    final secretBox = SecretBox(
      encryptedFile.ciphertext,
      nonce: encryptedFile.nonce,
      mac: Mac(encryptedFile.mac),
    );

    // Decrypt and validate (AES-GCM checks MAC automatically)
    try {
      final plaintext = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw Exception('Decryption failed: Invalid key or corrupted data - $e');
    }
  }

  /// Generates a SHA-256 hash of data for integrity verification
  static Future<List<int>> generateHash(Uint8List data) async {
    final sha256 = Sha256();
    final digest = await sha256.hash(data);
    return digest.bytes;
  }

  /// Converts key bytes to hex string for transmission
  static String keyBytesToHex(Uint8List keyBytes) {
    return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Converts hex string back to key bytes for decryption
  static Uint8List hexToKeyBytes(String hexString) {
    final bytes = <int>[];
    for (int i = 0; i < hexString.length; i += 2) {
      bytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

/// Encapsulates encrypted file data with all necessary metadata
class EncryptedFile {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;
  final Uint8List keyBytes;

  EncryptedFile({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
    required this.keyBytes,
  });

  /// Serialize encrypted file to JSON (for transmission)
  Map<String, dynamic> toJson() => {
        'ciphertext': base64Encode(ciphertext),
        'nonce': base64Encode(Uint8List.fromList(nonce)),
        'mac': base64Encode(Uint8List.fromList(mac)),
        'keyBytes': base64Encode(keyBytes),
      };

  /// Deserialize encrypted file from JSON
  factory EncryptedFile.fromJson(Map<String, dynamic> json) => EncryptedFile(
        ciphertext: base64Decode(json['ciphertext'] as String),
        nonce: base64Decode(json['nonce'] as String),
        mac: base64Decode(json['mac'] as String),
        keyBytes: base64Decode(json['keyBytes'] as String),
      );
}
