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
        String signedJson;
        try {
          final decoded = base64Decode(signed);
          signedJson = utf8.decode(decoded);
        } catch (_) {
          signedJson = Uri.decodeComponent(signed);
        }

        _logger.d('Parsed signed payload: $signedJson');

        // Submit signed transaction to Sui RPC via service
        final txDigest = await suiService.submitSignedTransaction(signedJson);
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
