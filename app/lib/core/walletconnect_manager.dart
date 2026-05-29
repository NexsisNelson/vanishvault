import 'dart:async';
import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

class WalletConnectManager {
  final Logger _logger;
  WalletConnect? _connector;
  SessionStatus? _session;
  final FlutterSecureStorage _storage;

  static const _kStorageKeyBridge = 'wc_bridge';
  static const _kStorageKeyAccounts = 'wc_accounts';

  WalletConnectManager({Logger? logger})
      : _logger = logger ?? Logger(),
        _storage = const FlutterSecureStorage();

  bool get connected => _connector?.connected ?? false;
  List<String> get accounts => _session?.accounts ?? [];

  Future<void> connect(
      {String bridge = 'https://bridge.walletconnect.org'}) async {
    _connector = WalletConnect(
      bridge: bridge,
      clientMeta: const PeerMeta(
        name: 'VanishVault',
        description: 'VanishVault mobile app',
        url: 'https://vanishvault.app',
        icons: [],
      ),
    );

    _connector!.on('connect', (session) {
      _logger.i('WC connect event: $session');
    });

    _connector!.on('session_update', (payload) {
      _logger.i('WC session_update: $payload');
    });

    _connector!.on('disconnect', (payload) async {
      _logger.i('WC disconnect: $payload');
      await _clearStoredSession();
    });

    _session = await _connector!.createSession(onDisplayUri: (uri) async {
      _logger.i('Open wallet for URI: $uri');
      // Open wallet app to approve
      if (await canLaunchUrl(Uri.parse(uri))) {
        await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
      }
    });

    // Persist basic info
    await _storage.write(key: _kStorageKeyBridge, value: bridge);
    await _storage.write(
        key: _kStorageKeyAccounts, value: _session?.accounts.join(','));
  }

  Future<void> disconnect() async {
    try {
      await _connector?.killSession();
    } catch (e) {
      _logger.w('Error disconnecting: $e');
    }
    _connector = null;
    _session = null;
    await _clearStoredSession();
  }

  Future<void> _clearStoredSession() async {
    await _storage.delete(key: _kStorageKeyBridge);
    await _storage.delete(key: _kStorageKeyAccounts);
  }

  Future<Map<String, String?>> restoreInfo() async {
    final bridge = await _storage.read(key: _kStorageKeyBridge);
    final accounts = await _storage.read(key: _kStorageKeyAccounts);
    return {'bridge': bridge, 'accounts': accounts};
  }
}
