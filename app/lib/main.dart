import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/deep_link_handler.dart';
import 'core/providers.dart';
import 'features/upload_screen.dart';
import 'features/retrieve_screen.dart';
import 'features/wallet_session_screen.dart';

void main() {
  runApp(const ProviderScope(child: VanishVaultApp()));
}

class VanishVaultApp extends StatelessWidget {
  const VanishVaultApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VanishVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const DeepLinkListenerWidget(child: HomeScreen()),
    );
  }
}

class DeepLinkListenerWidget extends ConsumerStatefulWidget {
  final Widget child;
  const DeepLinkListenerWidget({required this.child, Key? key})
      : super(key: key);

  @override
  ConsumerState<DeepLinkListenerWidget> createState() =>
      _DeepLinkListenerWidgetState();
}

class _DeepLinkListenerWidgetState
    extends ConsumerState<DeepLinkListenerWidget> {
  late DeepLinkHandler _handler;

  @override
  void initState() {
    super.initState();
    _handler = DeepLinkHandler();
    // Start listening once SuiBlockchainService is available
    final suiService = ref.read(suiBlockchainProvider);
    _handler.startListening(suiService);
  }

  @override
  void dispose() {
    _handler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VanishVault'), elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'VanishVault',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Decentralized Self-Destructing File Storage',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FileUploadScreen()),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Encrypt & Upload'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RetrieveScreen()),
                );
              },
              icon: const Icon(Icons.file_download),
              label: const Text('Retrieve Files'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const WalletSessionScreen()));
              },
              icon: const Icon(Icons.link),
              label: const Text('Wallet Sessions'),
            ),
          ],
        ),
      ),
    );
  }
}
