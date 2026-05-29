import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

class FileUploadScreen extends ConsumerStatefulWidget {
  const FileUploadScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends ConsumerState<FileUploadScreen> {
  final _receiverController = TextEditingController();
  final _walletController = TextEditingController();
  String _selectedWallet = 'WalletConnect';
  String? _selectedFilePath;

  @override
  void dispose() {
    _receiverController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileOpState = ref.watch(fileOperationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload File')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // File Selection Card
          Card(
            child: InkWell(
              onTap: fileOpState.isLoading ? null : _selectFile,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFilePath ?? 'Tap to select file',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Receiver Address Input
          TextField(
            controller: _receiverController,
            decoration: const InputDecoration(
              labelText: 'Receiver Sui Address',
              hintText: 'Enter receiver Sui address (0x...)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_circle_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // Wallet Address Input (uploader)
          // Wallet Selection
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedWallet,
                  items: const [
                    DropdownMenuItem(
                        value: 'WalletConnect', child: Text('WalletConnect')),
                    DropdownMenuItem(value: 'Phantom', child: Text('Phantom')),
                    DropdownMenuItem(value: 'Slush', child: Text('Slush')),
                    DropdownMenuItem(value: 'Bitget', child: Text('Bitget')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedWallet = v ?? 'WalletConnect'),
                  decoration: const InputDecoration(
                    labelText: 'Wallet',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _walletController,
                  decoration: const InputDecoration(
                    labelText: 'Your Wallet Address',
                    hintText: 'Enter your wallet address (for signing)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),

          // Password Requirements
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Requirements:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  _RequirementItem('At least 12 characters'),
                  _RequirementItem('Mix of upper and lowercase'),
                  _RequirementItem('Numbers and special characters'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upload Progress
          if (fileOpState.isLoading)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fileOpState.progress,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(fileOpState.progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

          // Error Display
          if (fileOpState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  fileOpState.error!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Upload Button
          ElevatedButton.icon(
            onPressed: _selectedFilePath != null &&
                    _receiverController.text.isNotEmpty &&
                    _walletController.text.isNotEmpty &&
                    !fileOpState.isLoading
                ? _uploadFile
                : null,
            icon: const Icon(Icons.upload),
            label: const Text('Encrypt & Upload'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Display generated key/material after upload
          if (!fileOpState.isLoading && fileOpState.progress == 1.0)
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _selectFile() {
    // Placeholder: Implement file picker
    setState(() {
      _selectedFilePath = '/storage/emulated/0/Documents/example.pdf';
    });
  }

  Future<void> _uploadFile() async {
    // Show non-dismissible progress dialog while upload + signing occurs
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Waiting for wallet signature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Please approve the transaction in your wallet...'),
          ],
        ),
      ),
    );

    try {
      final result = await ref.read(fileOperationProvider.notifier).uploadFile(
            filePath: _selectedFilePath!,
            receiverAddress: _receiverController.text,
            walletAddress: _walletController.text,
            wallet: _selectedWallet,
          );

      // Close progress dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        final tx = result['txDigest'];
        final blobId = result['blobId'];
        final keyHex = result['keyHex'];
        final nonce = result['nonce'];
        final mac = result['mac'];

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Shareable Key Material'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tx: $tx'),
                  const SizedBox(height: 8),
                  SelectableText('Blob ID: $blobId'),
                  const SizedBox(height: 8),
                  SelectableText('Key (hex): $keyHex'),
                  const SizedBox(height: 8),
                  SelectableText('Nonce (base64): $nonce'),
                  const SizedBox(height: 8),
                  SelectableText('MAC (base64): $mac'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close progress dialog if open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;

  const _RequirementItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
