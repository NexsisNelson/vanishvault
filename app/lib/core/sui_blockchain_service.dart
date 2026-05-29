import 'package:logger/logger.dart';

/// Handles Sui blockchain interactions for VanishVault
/// This service builds and signs transactions for the Move contract
class SuiBlockchainService {
  final String rpcUrl;
  final String packageId;
  final Logger _logger;

  SuiBlockchainService({
    required this.rpcUrl,
    required this.packageId,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  /// Initialize wallet connection (placeholder for actual implementation)
  /// In production, this would establish connection with Sui Wallet
  Future<void> connectWallet() async {
    try {
      _logger.i('Connecting to Sui wallet...');
      // Implementation would use sui package to connect wallet
      _logger.i('Wallet connected');
    } catch (e) {
      _logger.e('Failed to connect wallet: $e');
      rethrow;
    }
  }

  /// Entry point: Register a DataRoom on the Sui blockchain
  /// This is called by the uploader's frontend after uploading to Walrus
  ///
  /// Constructs and signs a transaction block (PTB) that calls:
  ///   create_room(walrus_blob_id: u256, receiver: address, clock: &Clock)
  ///
  /// Returns the transaction digest
  Future<String> registerDataRoom({
    required String blobId,
    required String receiverAddress,
    required String walletAddress,
  }) async {
    try {
      _logger.i('Registering DataRoom on Sui blockchain...');
      _logger.i('  Blob ID: $blobId');
      _logger.i('  Receiver: $receiverAddress');

      // Convert hex blob ID string to u256 (BigInt)
      final blobIdBigInt = _hexStringToU256(blobId);

      // Build TransactionBlock (PTB)
      final ptb = _buildRegisterDataRoomTransaction(
        blobIdBigInt: blobIdBigInt,
        receiverAddress: receiverAddress,
      );

      _logger.d('Transaction block built: $ptb');

      // Sign and execute transaction (placeholder - actual impl uses sui package)
      final txDigest = _signAndExecuteTransaction(
        ptb: ptb,
        walletAddress: walletAddress,
      );

      _logger.i('DataRoom registered. Tx: $txDigest');
      return txDigest;
    } catch (e) {
      _logger.e('Failed to register DataRoom: $e');
      rethrow;
    }
  }

  /// Fetch blob ID from the blockchain
  /// Calls the read-only get_blob_id() function on the Move contract
  ///
  /// This function:
  /// 1. Verifies the caller is the authorized receiver
  /// 2. Checks that the 24-hour timer hasn't expired
  /// 3. Returns the Walrus blob ID if both checks pass
  Future<String> fetchBlobIdFromChain(String dataRoomObjectId) async {
    try {
      _logger.i('Fetching blob ID from Sui contract...');

      // Call get_blob_id() on the contract (read-only)
      // The contract will verify authorization and expiration
      final blobIdU256 = await _callGetBlobId(dataRoomObjectId);

      // Convert u256 back to hex string
      final blobIdHex = _u256ToHexString(blobIdU256);

      _logger.i('Blob ID retrieved: $blobIdHex');
      return blobIdHex;
    } catch (e) {
      _logger.e('Failed to fetch blob ID: $e');
      rethrow;
    }
  }

  /// Destroy a DataRoom on the blockchain
  /// Calls destroy_and_expire() which permanently deletes the DataRoom object
  ///
  /// Can be called by:
  /// - The creator at any time
  /// - Anyone if the DataRoom has expired (automated cleanup)
  Future<String> destroyAndExpire(String dataRoomObjectId) async {
    try {
      _logger.i('Destroying DataRoom on Sui blockchain...');

      // Build destroy transaction
      final ptb = _buildDestroyTransaction(dataRoomObjectId);

      // Sign and execute (placeholder)
      final txDigest = await _executeDestroyTransaction(ptb);

      _logger.i('DataRoom destroyed. Tx: $txDigest');
      return txDigest;
    } catch (e) {
      _logger.e('Failed to destroy DataRoom: $e');
      rethrow;
    }
  }

  /// Check if a DataRoom has expired based on the blockchain clock
  Future<bool> hasDataRoomExpired(String dataRoomObjectId) async {
    try {
      // Query contract state for expiration time
      final isExpired = await _queryIsExpired(dataRoomObjectId);
      return isExpired;
    } catch (e) {
      _logger.e('Failed to check expiration: $e');
      return true; // Fail safe: assume expired
    }
  }

  /// Get time remaining until DataRoom expires (in milliseconds)
  Future<Duration> getTimeUntilExpiration(String dataRoomObjectId) async {
    try {
      final remainingMs = await _queryTimeUntilExpiration(dataRoomObjectId);
      return Duration(milliseconds: remainingMs);
    } catch (e) {
      _logger.e('Failed to get remaining time: $e');
      return Duration.zero; // Fail safe
    }
  }

  // ============= Helper Methods =============

  /// Convert hex string (0x...) to u256 (BigInt)
  BigInt _hexStringToU256(String hexString) {
    final cleanHex = hexString.startsWith('0x')
        ? hexString.substring(2)
        : hexString;
    return BigInt.parse(cleanHex, radix: 16);
  }

  /// Convert u256 (BigInt) to hex string (0x...)
  String _u256ToHexString(BigInt value) {
    return '0x${value.toRadixString(16)}';
  }

  /// Build a ProgrammableTransactionBlock for registering a DataRoom
  Map<String, dynamic> _buildRegisterDataRoomTransaction({
    required BigInt blobIdBigInt,
    required String receiverAddress,
  }) {
    return {
      'kind': 'ProgrammableTransaction',
      'inputs': [
        {'kind': 'pure', 'value': blobIdBigInt.toString(), 'valueType': 'u256'},
        {'kind': 'pure', 'value': receiverAddress, 'valueType': 'address'},
        {
          'kind': 'object',
          'objectId': '0x6',
          'version': 0, // System clock object
          'digest': 'Hs6vWJhGyqWzPQb3EKxbN1Q9xdNLNSvGVmfnhddpV5p',
          'mutable': false,
        },
      ],
      'transactions': [
        {
          'MoveCall': {
            'package': packageId,
            'module': 'vanishvault',
            'function': 'create_room',
            'typeArguments': [],
            'arguments': [0, 1, 2], // Input indices
          },
        },
      ],
    };
  }

  /// Build a destroy transaction
  Map<String, dynamic> _buildDestroyTransaction(String dataRoomObjectId) {
    return {
      'kind': 'ProgrammableTransaction',
      'inputs': [
        {'kind': 'object', 'objectId': dataRoomObjectId, 'mutable': true},
        {
          'kind': 'object',
          'objectId': '0x6', // System clock
          'version': 0,
          'digest': 'Hs6vWJhGyqWzPQb3EKxbN1Q9xdNLNSvGVmfnhddpV5p',
          'mutable': false,
        },
      ],
      'transactions': [
        {
          'MoveCall': {
            'package': packageId,
            'module': 'vanishvault',
            'function': 'destroy_and_expire',
            'typeArguments': [],
            'arguments': [0, 1],
          },
        },
      ],
    };
  }

  /// Sign and execute a transaction block (placeholder)
  /// In production, this would use @mysten/sui.js to sign via wallet
  String _signAndExecuteTransaction({
    required Map<String, dynamic> ptb,
    required String walletAddress,
  }) {
    _logger.d('Signing transaction with wallet: $walletAddress');
    // Placeholder: actual implementation would sign with wallet SDK
    return 'txn_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Call get_blob_id() on the contract (placeholder)
  Future<BigInt> _callGetBlobId(String dataRoomObjectId) async {
    _logger.d('Calling get_blob_id for DataRoom: $dataRoomObjectId');
    // Placeholder: actual implementation would call via RPC
    return BigInt.parse('0', radix: 16);
  }

  /// Execute destroy transaction (placeholder)
  Future<String> _executeDestroyTransaction(Map<String, dynamic> ptb) async {
    _logger.d('Executing destroy transaction...');
    // Placeholder
    return 'destroy_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Query is_expired() function (placeholder)
  Future<bool> _queryIsExpired(String dataRoomObjectId) async {
    _logger.d('Querying expiration status...');
    // Placeholder
    return false;
  }

  /// Query time_until_expiration() function (placeholder)
  Future<int> _queryTimeUntilExpiration(String dataRoomObjectId) async {
    _logger.d('Querying time until expiration...');
    // Placeholder
    return 86400000; // 24 hours
  }
}
