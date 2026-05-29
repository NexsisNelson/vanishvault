import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:uni_links/uni_links.dart';
import 'sui_blockchain_service.dart';

/// Handles incoming deep-links and routes signed transactions back to the Sui service
class DeepLinkHandler {
  final Logger _logger;
  StreamSubscription? _sub;

  DeepLinkHandler({Logger? logger}) : _logger = logger ?? Logger();

  /// Start listening for incoming URIs. When a signed tx callback arrives,
  /// extract the signed payload and call `submitSignedTransaction` on the provided service.
  void startListening(SuiBlockchainService suiService) {
    // Cancel existing
    _sub?.cancel();

    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;
      _logger.i('Deep link received: $uri');

      try {
        // Expected forms:
        // vanishvault://signed_tx_callback?signed_tx=<base64 or json>
        // vanishvault://signed_tx_callback?payload=<base64 or json>
        String? signed = uri.queryParameters['signed_tx'] ??
            uri.queryParameters['payload'] ??
            uri.queryParameters['signed'];
        if (signed == null) {
          _logger
              .w('No signed_tx or payload query parameter found in deep link');
          return;
        }

        // Try base64 decode, otherwise treat as JSON string
        String signedJsonRaw;
        try {
          final decoded = base64Decode(signed);
          signedJsonRaw = utf8.decode(decoded);
        } catch (_) {
          signedJsonRaw = Uri.decodeComponent(signed);
        }

        _logger.d('Parsed raw signed payload: $signedJsonRaw');

        // Heuristic parsing for wallet-specific wrappers (Phantom/Slush etc.)
        String finalSignedPayload = signedJsonRaw;
        try {
          final parsed = jsonDecode(signedJsonRaw);
          if (parsed is Map<String, dynamic>) {
            // Common wrapper keys that wallets may use
            final candidates = [
              'signed_tx',
              'signedTx',
              'signedTransaction',
              'signed',
              'tx',
              'txBytes',
              'tx_bytes',
              'result',
              'data',
              'payload'
            ];

            String? extracted;
            for (final k in candidates) {
              if (parsed.containsKey(k)) {
                final v = parsed[k];
                if (v is String) {
                  extracted = v;
                  break;
                } else if (v is Map || v is List) {
                  extracted = jsonEncode(v);
                  break;
                }
              }
            }

            // Some wallets nest the signed tx inside `result` -> `txBytes` or similar
            if (extracted == null && parsed.containsKey('result')) {
              final r = parsed['result'];
              if (r is Map) {
                for (final k in [
                  'txBytes',
                  'tx_bytes',
                  'signedTransaction',
                  'signed_tx'
                ]) {
                  if (r.containsKey(k)) {
                    final v = r[k];
                    extracted = v is String ? v : jsonEncode(v);
                    break;
                  }
                }
              }
            }

            if (extracted != null) {
              // Try to base64-decode inner value if it looks encoded
              try {
                final innerDecoded = base64Decode(extracted);
                finalSignedPayload = utf8.decode(innerDecoded);
              } catch (_) {
                finalSignedPayload = extracted;
              }
            } else {
              // If no wrapper found, keep original raw JSON string
              finalSignedPayload = jsonEncode(parsed);
            }
          }
        } catch (e) {
          _logger
              .d('DeepLinkHandler: payload is not JSON or parsing failed: $e');
        }

        _logger.d('Final signed payload to submit: $finalSignedPayload');

        // Submit signed transaction to Sui RPC via service
        final txDigest =
            await suiService.submitSignedTransaction(finalSignedPayload);
        _logger.i('Submitted signed tx. Digest: $txDigest');
      } catch (e) {
        _logger.e('Failed to handle deep link: $e');
      }
    }, onError: (err) {
      _logger.e('Deep link stream error: $err');
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}
