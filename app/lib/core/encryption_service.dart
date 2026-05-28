import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Handles AES-256-GCM encryption and decryption
class EncryptionService {
  static const _algorithm = AesGcm.with256bits;

  /// Encrypts data using AES-256-GCM
  static Future<EncryptedData> encrypt(
    Uint8List plaintext,
    String passphrase,
  ) async {
    // Derive key from passphrase using PBKDF2
    final secretKey = await _deriveKeyFromPassphrase(passphrase);

    // Generate nonce
    final nonce = _algorithm.newNonce();

    // Encrypt
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptedData(
      ciphertext: secretBox.cipherText,
      nonce: nonce,
      mac: secretBox.mac.bytes,
    );
  }

  /// Decrypts data using AES-256-GCM
  static Future<Uint8List> decrypt(
    EncryptedData encryptedData,
    String passphrase,
  ) async {
    // Derive key from passphrase
    final secretKey = await _deriveKeyFromPassphrase(passphrase);

    // Create SecretBox from encrypted data
    final secretBox = SecretBox(
      encryptedData.ciphertext,
      nonce: encryptedData.nonce,
      mac: Mac(encryptedData.mac),
    );

    // Decrypt
    try {
      final plaintext = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Derives a key from passphrase using PBKDF2
  static Future<SecretKey> _deriveKeyFromPassphrase(String passphrase) async {
    const salt = 'vanishvault_salt'; // Should be random in production
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(Sha256()),
      iterations: 10000,
      bits: 256,
    );

    return await pbkdf2.deriveBits(utf8.encode(passphrase), utf8.encode(salt));
  }

  /// Generates a content hash for verification
  static Future<List<int>> generateHash(Uint8List data) async {
    final sha256 = Sha256();
    final digest = await sha256.bind(data).first;
    return digest.bytes;
  }
}

/// Represents encrypted data with metadata
class EncryptedData {
  final Uint8List ciphertext;
  final List<int> nonce;
  final List<int> mac;

  EncryptedData({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
    'ciphertext': base64Encode(ciphertext),
    'nonce': base64Encode(Uint8List.fromList(nonce)),
    'mac': base64Encode(Uint8List.fromList(mac)),
  };

  /// Deserialize from JSON
  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
    ciphertext: base64Decode(json['ciphertext'] as String),
    nonce: base64Decode(json['nonce'] as String),
    mac: base64Decode(json['mac'] as String),
  );
}
