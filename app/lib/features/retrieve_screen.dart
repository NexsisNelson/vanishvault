import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RetrieveScreen extends ConsumerStatefulWidget {
  const RetrieveScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RetrieveScreen> createState() => _RetrieveScreenState();
}

class _RetrieveScreenState extends ConsumerState<RetrieveScreen> {
  final _blobIdController = TextEditingController();
  final _keyHexController = TextEditingController();
  final _nonceController = TextEditingController();
  final _macController = TextEditingController();
  bool _showPassphrase = false;

  @override
  void dispose() {
    _blobIdController.dispose();
    _keyHexController.dispose();
    _nonceController.dispose();
    _macController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileOpState = ref.watch(fileOperationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Retrieve File')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Blob ID Input
          TextField(
            controller: _blobIdController,
            decoration: InputDecoration(
              labelText: 'Blob ID',
              hintText: 'Paste the blob ID here',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 24),

          // Key Hex
          TextField(
            controller: _keyHexController,
            decoration: const InputDecoration(
              labelText: 'Key (hex)',
              hintText: 'Paste key hex from sender',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Nonce (base64)
          TextField(
            controller: _nonceController,
            decoration: const InputDecoration(
              labelText: 'Nonce (base64)',
              hintText: 'Paste nonce (base64)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // MAC (base64)
          TextField(
            controller: _macController,
            decoration: const InputDecoration(
              labelText: 'MAC (base64)',
              hintText: 'Paste MAC (base64)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),

          // Info Card
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• File can only be retrieved within 24 hours of upload',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Passphrase is required for decryption',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• File will be automatically destroyed after 24 hours',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Download Progress
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

          // Retrieve Button
          ElevatedButton.icon(
            onPressed: _blobIdController.text.isNotEmpty &&
                    _keyHexController.text.isNotEmpty &&
                    _nonceController.text.isNotEmpty &&
                    _macController.text.isNotEmpty &&
                    !fileOpState.isLoading
                ? _retrieveFile
                : null,
            icon: const Icon(Icons.download),
            label: const Text('Download & Decrypt'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retrieveFile() async {
    try {
      final plaintext =
          await ref.read(fileOperationProvider.notifier).retrieveFile(
                dataRoomObjectId: _blobIdController.text.trim(),
                keyHex: _keyHexController.text.trim(),
                nonceBase64: _nonceController.text.trim(),
                macBase64: _macController.text.trim(),
              );

      // Save plaintext to device
      final savedPath = await ref
          .read(localFileServiceProvider)
          .saveFile(plaintext, 'retrieved_file');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File retrieved and saved: $savedPath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Retrieval failed: $e')));
      }
    }
  }
}
