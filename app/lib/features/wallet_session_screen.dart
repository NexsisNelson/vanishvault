import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/walletconnect_manager.dart';

final walletConnectManagerProvider = Provider((ref) => WalletConnectManager());

class WalletSessionScreen extends ConsumerStatefulWidget {
  const WalletSessionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WalletSessionScreen> createState() =>
      _WalletSessionScreenState();
}

class _WalletSessionScreenState extends ConsumerState<WalletSessionScreen> {
  bool _isConnecting = false;
  Map<String, String?> _stored = {};

  @override
  void initState() {
    super.initState();
    _loadStored();
  }

  Future<void> _loadStored() async {
    final mgr = ref.read(walletConnectManagerProvider);
    final info = await mgr.restoreInfo();
    setState(() => _stored = info);
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    final mgr = ref.read(walletConnectManagerProvider);
    try {
      await mgr.connect();
      await _loadStored();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Connect failed: $e')));
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    final mgr = ref.read(walletConnectManagerProvider);
    await mgr.disconnect();
    await _loadStored();
  }

  @override
  Widget build(BuildContext context) {
    final mgr = ref.watch(walletConnectManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('WalletConnect Session')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stored bridge: ${_stored['bridge'] ?? 'None'}'),
            const SizedBox(height: 8),
            Text('Stored accounts: ${_stored['accounts'] ?? 'None'}'),
            const SizedBox(height: 16),
            if (_isConnecting) const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isConnecting ? null : _connect,
                  child: const Text('Connect'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: mgr.connected ? _disconnect : null,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Notes:'),
            const SizedBox(height: 4),
            const Text(
                '- Session persistence stores last bridge and accounts in secure storage.'),
            const Text(
                '- For a full persistent WalletConnect session across restarts, a more advanced session-serialization is required.'),
          ],
        ),
      ),
    );
  }
}
