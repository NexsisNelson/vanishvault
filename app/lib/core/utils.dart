/// Utility functions for VanishVault
library vanishvault_utils;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Format bytes to human-readable size
String formatBytes(int bytes) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(2)) + " " + suffixes[i];
}

/// Format duration to readable string
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

/// Validate passphrase strength
PassphraseStrength validatePassphrase(String passphrase) {
  if (passphrase.length < 12) {
    return PassphraseStrength.weak;
  }

  bool hasUppercase = passphrase.contains(RegExp(r'[A-Z]'));
  bool hasLowercase = passphrase.contains(RegExp(r'[a-z]'));
  bool hasNumbers = passphrase.contains(RegExp(r'[0-9]'));
  bool hasSpecialChars = passphrase.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  int strengthScore = 0;
  if (hasUppercase) strengthScore++;
  if (hasLowercase) strengthScore++;
  if (hasNumbers) strengthScore++;
  if (hasSpecialChars) strengthScore++;

  if (passphrase.length >= 16 && strengthScore == 4) {
    return PassphraseStrength.veryStrong;
  } else if (passphrase.length >= 14 && strengthScore >= 3) {
    return PassphraseStrength.strong;
  } else if (passphrase.length >= 12 && strengthScore >= 2) {
    return PassphraseStrength.moderate;
  } else {
    return PassphraseStrength.weak;
  }
}

enum PassphraseStrength { weak, moderate, strong, veryStrong }

/// Convert bytes to Base64
String bytesToBase64(Uint8List bytes) => base64Encode(bytes);

/// Convert Base64 to bytes
Uint8List base64ToBytes(String encoded) => base64Decode(encoded);

/// Truncate string to length with ellipsis
String truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Generate a random string
String generateRandomString(int length) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789';
  final random = <String>[];
  for (int i = 0; i < length; i++) {
    random.add(chars[DateTime.now().microsecond % chars.length]);
  }
  return random.join();
}
