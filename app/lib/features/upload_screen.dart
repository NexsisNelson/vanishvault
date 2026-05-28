import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileUploadScreen extends ConsumerStatefulWidget {
  const FileUploadScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends ConsumerState<FileUploadScreen> {
  String? _selectedFilePath;
  final _passphraseController = TextEditingController();
  bool _showPassphrase = false;

  @override
  void dispose() {
    _passphraseController.dispose();
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

          // Passphrase Input
          TextField(
            controller: _passphraseController,
            obscureText: !_showPassphrase,
            decoration: InputDecoration(
              labelText: 'Encryption Passphrase',
              hintText: 'Enter a strong passphrase',
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
            onPressed:
                _selectedFilePath != null &&
                    _passphraseController.text.isNotEmpty &&
                    !fileOpState.isLoading
                ? _uploadFile
                : null,
            icon: const Icon(Icons.upload),
            label: const Text('Encrypt & Upload'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
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
    try {
      final digest = await ref
          .read(fileOperationProvider.notifier)
          .uploadFile(
            filePath: _selectedFilePath!,
            passphrase: _passphraseController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File uploaded! Tx: $digest'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy to clipboard
              },
            ),
          ),
        );
      }
    } catch (e) {
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
