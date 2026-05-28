/// Application-wide constants and configuration
class AppConfig {
  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableDebugLogging = true;
  static const bool enableCrashReporting = false;

  // Timeouts
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration downloadTimeout = Duration(minutes: 5);
  static const Duration walletTimeout = Duration(seconds: 30);
  static const Duration rpcTimeout = Duration(seconds: 30);

  // File Limits
  static const int maxFileSize = 100 * 1024 * 1024; // 100 MB
  static const int maxBatchUpload = 10; // Files per batch

  // Encryption
  static const int pbkdf2Iterations = 10000;
  static const int encryptionKeyBits = 256;
  static const int nonceBytes = 12;

  // Blockchain
  static const int gasLimit = 10000000;
  static const String suiRpcUrl = 'https://fullnode.mainnet.sui.io';
  static const String suiTestnetRpc = 'https://fullnode.testnet.sui.io';

  // Walrus
  static const String walrusMainnetUrl = 'https://walrus.mainnet.sui.io';
  static const String walrusTestnetUrl = 'https://walrus.testnet.sui.io';

  // Timer Configuration
  static const Duration selfDestructionTimer = Duration(hours: 24);
  static const Duration gracePeriod = Duration(minutes: 5);

  // Retry Policy
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const double retryBackoffMultiplier = 1.5;

  // UI Constants
  static const String appName = 'VanishVault';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Decentralized Self-Destructing File Storage';

  // Security
  static const String passphraseSaltLength = 'vanishvault_salt';
  static const bool requireBiometricAuth = true;
}

/// Environment-specific configuration
enum Environment { dev, staging, production }

class EnvironmentConfig {
  static Environment current = Environment.production;

  static String get suiRpc {
    switch (current) {
      case Environment.dev:
        return AppConfig.suiTestnetRpc;
      case Environment.staging:
        return AppConfig.suiTestnetRpc;
      case Environment.production:
        return AppConfig.suiRpcUrl;
    }
  }

  static String get walrusUrl {
    switch (current) {
      case Environment.dev:
        return AppConfig.walrusTestnetUrl;
      case Environment.staging:
        return AppConfig.walrusTestnetUrl;
      case Environment.production:
        return AppConfig.walrusMainnetUrl;
    }
  }

  static bool get debugMode => current != Environment.production;
}
