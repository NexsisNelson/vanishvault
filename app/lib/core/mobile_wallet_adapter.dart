import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:logger/logger.dart';

/// Mobile wallet adapter: prefers WalletConnect, falls back to deep-links.
class MobileWalletAdapter {
  final Logger _logger;
  WalletConnect? _connector;
  SessionStatus? _session;

  MobileWalletAdapter({Logger? logger}) : _logger = logger ?? Logger();

  /// Connect via WalletConnect (returns true if connected)
  Future<bool> connectWithWalletConnect({required String bridge}) async {
    try {
      _connector = WalletConnect(
        bridge: bridge,
        clientMeta: const PeerMeta(
          name: 'VanishVault',
          description: 'VanishVault mobile app',
          url: 'https://vanishvault.app',
          icons: [],
        ),
      );

      if (!_connector!.connected) {
        _session = await _connector!.createSession(
          onDisplayUri: (uri) async {
            _logger.i('WalletConnect URI: $uri');
            // Try opening the wallet using the URI
            if (await canLaunchUrl(Uri.parse(uri))) {
              await launchUrl(Uri.parse(uri),
                  mode: LaunchMode.externalApplication);
            }
          },
        );
      }

      return _connector!.connected;
    } catch (e) {
      _logger.w('WalletConnect failed: $e');
      return false;
    }
  }

  /// Request a wallet to sign & execute a Sui transaction via WalletConnect
  /// This is a best-effort generic implementation and may require wallet-specific methods.
  Future<String> requestSignAndExecuteWithWalletConnect({
    required Map<String, dynamic> txRequest,
  }) async {
    if (_connector == null || !_connector!.connected) {
      throw Exception('WalletConnect not connected');
    }

    try {
      // Send a custom request; wallets may implement `sui_signAndExecuteTransaction`
      final result = await _connector!.sendCustomRequest(
          method: 'sui_signAndExecuteTransaction', params: [txRequest]);
      return result.toString();
    } catch (e) {
      _logger.w('WalletConnect sign/execute failed: $e');
      rethrow;
    }
  }

  /// Build a deep-link URL for supported wallets as a fallback.
  String buildDeepLinkForWallet(
      {required String wallet,
      required String payload,
      required String callbackUrl}) {
    // Common pattern: <wallet>://sign?payload=<payload>&callback=<callbackUrl>
    final encoded = Uri.encodeComponent(payload);
    final cb = Uri.encodeComponent(callbackUrl);

    switch (wallet.toLowerCase()) {
      case 'phantom':
        return 'phantom://sign?payload=$encoded&redirect_link=$cb';
      case 'slush':
        return 'slush://sui/sign?payload=$encoded&callback=$cb';
      case 'bitget':
        return 'bitget://wallet/sui/sign?payload=$encoded&callback=$cb';
      default:
        return '$wallet://sign?payload=$encoded&callback=$cb';
    }
  }

  /// Open deep-link and wait for the user to return to the app.
  Future<void> openDeepLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Cannot open deep link: $url');
    }
  }
}
