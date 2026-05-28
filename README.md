# VanishVault

**Decentralized, cross-platform file storage with 24-hour self-destruction.**

VanishVault is a sophisticated mobile application that combines Flutter/Dart frontend, Sui blockchain smart contracts, and Walrus P2P storage to create a secure, tamper-proof system for temporary file sharing.

## 🎯 Features

- **Local Encryption**: AES-256-GCM encryption on device before upload
- **Decentralized Storage**: Walrus P2P network for distributed file storage
- **Blockchain Timer**: Sui smart contracts enforce cryptographic 24-hour self-destruction
- **Cross-Platform**: iOS and Android support via Flutter
- **Zero-Knowledge**: Server-side decryption impossible; only owner can decrypt
- **Tamper-Proof**: Smart contract prevents premature or delayed destruction
- **Wallet Integration**: Sui wallet connection for transaction signing

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│   Flutter/Dart Frontend (iOS/Android)   │
├─────────────────────────────────────────┤
│ • Encryption (AES-256-GCM)              │
│ • File Management                        │
│ • Wallet Integration                     │
├─────────────────────────────────────────┤
│   Sui Blockchain Layer                  │
├─────────────────────────────────────────┤
│ • Smart Contracts (Move)                │
│ • 24-Hour Destruction Timer             │
│ • Event Emissions                        │
├─────────────────────────────────────────┤
│   Walrus Storage Network                │
├─────────────────────────────────────────┤
│ • P2P File Distribution                 │
│ • Blob Storage & Retrieval              │
└─────────────────────────────────────────┘
```

## 📱 Project Structure

```
vanishvault/
├── app/                           # Flutter/Dart application
│   ├── lib/
│   │   ├── core/                  # Core services
│   │   │   ├── encryption_service.dart        # AES-256-GCM encryption
│   │   │   ├── walrus_storage_service.dart    # Walrus integration
│   │   │   ├── sui_blockchain_service.dart    # Sui RPC & contracts
│   │   │   ├── local_file_service.dart        # Device file operations
│   │   │   └── providers.dart                 # Riverpod state management
│   │   ├── features/              # Feature-specific logic
│   │   ├── widgets/               # Reusable UI components
│   │   └── main.dart              # Entry point
│   ├── pubspec.yaml               # Dart dependencies
│   └── android/, ios/             # Platform-specific code
│
├── contracts/                     # Sui Move smart contracts
│   ├── sources/
│   │   └── vanishvault.move       # Main contract with destruction timer
│   ├── tests/                     # Move tests
│   └── Move.toml                  # Contract manifest
│
└── docs/                          # Documentation

```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.0+
- Dart 3.0+
- Sui CLI (for contract deployment)
- Node.js 18+ (optional, for scripts)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/vanishvault.git
   cd vanishvault
   ```

2. **Install Flutter dependencies**
   ```bash
   cd app
   flutter pub get
   flutter gen-l10n
   ```

3. **Build and run**
   ```bash
   flutter run -d <device_id>
   ```

4. **Deploy smart contracts** (requires Sui CLI)
   ```bash
   cd contracts
   sui client publish --gas-budget 10000000
   ```

## 🔐 Security Model

### Encryption Flow

1. **Local Encryption**: File is encrypted locally using AES-256-GCM with PBKDF2-derived key
2. **Upload**: Encrypted blob is sent to Walrus network (no server decryption possible)
3. **Blockchain Recording**: Smart contract stores file metadata and sets destruction timer
4. **24-Hour Window**: Owner can retrieve file within 24 hours
5. **Auto-Destruction**: After 24 hours, contract marks file as destroyed and emits event
6. **Cascading Deletion**: Frontend monitors events and purges local copies

### Security Properties

- **Confidentiality**: Only owner has passphrase; encryption key never transmitted
- **Integrity**: Content hash verified on retrieval
- **Non-Repudiation**: Sui blockchain records all actions cryptographically
- **Tamper-Proof**: Smart contract enforces strict 24-hour timer
- **Zero-Knowledge**: Walrus nodes cannot decrypt or read file content

## 📋 Smart Contract Functions

### Core Operations

```move
// Upload encrypted file
upload_file(walrus_path, content_hash, access_key) -> EncryptedFile

// Retrieve file access
retrieve_file(file, access_key) -> (path, key)

// Force destruction after 24 hours
destroy_file(file) -> event

// Query file status
get_file_info(file) -> (owner, created_at, destruction_time, is_destroyed)

// Check if file can be destroyed
can_destroy(file) -> bool

// Get time until destruction
time_until_destruction(file) -> u64
```

## 🔄 Data Flow

```
1. SELECT FILE
   ↓
2. ENCRYPT LOCALLY (AES-256-GCM)
   ↓
3. UPLOAD TO WALRUS
   ↓
4. RECORD ON SUI BLOCKCHAIN
   ↓
5. RETURN BLOB ID & TX DIGEST
   ↓
6. SHARE WITH RECIPIENT (BLOB ID)
   ↓
7. RECIPIENT ENTERS PASSPHRASE
   ↓
8. DOWNLOAD FROM WALRUS & DECRYPT
   ↓
9. AFTER 24 HOURS: AUTO-DESTRUCTION
```

## 🛠️ Development

### Build & Test

```bash
# Flutter tests
flutter test

# Smart contract tests
cd contracts && sui move test

# Code generation
dart run build_runner build
```

### Environment Variables

Create `.env.local` in the `app/` directory:

```
SUI_RPC_URL=https://fullnode.mainnet.sui.io
WALRUS_URL=https://walrus.mainnet.sui.io
PACKAGE_ID=0x... # Your deployed contract package ID
```

## 📦 Dependencies

### Frontend

- `flutter_riverpod` — State management
- `cryptography` — AES-256-GCM encryption
- `dio` — HTTP client for Walrus
- `sui` — Sui blockchain SDK
- `flutter_secure_storage` — Secure credential storage

### Contracts

- Sui Framework (latest)

## 🧪 Testing

### Smart Contract Tests

```bash
cd contracts
sui move test
```

### Flutter Tests

```bash
cd app
flutter test
```

## 📝 API Reference

See [docs/API.md](docs/API.md) for detailed API documentation.

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License — See [LICENSE](LICENSE)

## 🔗 Links

- [Sui Docs](https://docs.sui.io)
- [Walrus Docs](https://docs.walrus.site)
- [Flutter Docs](https://docs.flutter.dev)

---

**Built with ❤️ for secure, temporary file sharing.**
