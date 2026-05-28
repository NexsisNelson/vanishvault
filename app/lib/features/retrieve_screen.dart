import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RetrieveScreen extends ConsumerStatefulWidget {
  const RetrieveScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RetrieveScreen> createState() => _RetrieveScreenState();
}

class _RetrieveScreenState extends ConsumerState<RetrieveScreen> {
  final _blobIdController = TextEditingController();
  final _passphraseController = TextEditingController();
  bool _showPassphrase = false;

  @override
  void dispose() {
    _blobIdController.dispose();
    _passphraseController.dispose();
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

          // Passphrase Input
          TextField(
            controller: _passphraseController,
            obscureText: !_showPassphrase,
            decoration: InputDecoration(
              labelText: 'Decryption Passphrase',
              hintText: 'Enter the passphrase used during upload',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassphrase ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showPassphrase = !_showPassphrase;
                  });
                },
              ),
            ),
          ),
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
            onPressed:
                _blobIdController.text.isNotEmpty &&
                    _passphraseController.text.isNotEmpty &&
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
      // Implementation: call retrieve endpoint
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Retrieving file...')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Retrieval failed: $e')));
      }
    }
  }
}
