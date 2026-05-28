# VanishVault Development Workspace

Custom instructions and guidelines for the VanishVault project development.

## Project Overview

VanishVault is a decentralized, cross-platform app combining:
- **Frontend**: Flutter/Dart
- **Blockchain**: Sui Move smart contracts
- **Storage**: Walrus P2P network
- **Security**: AES-256-GCM encryption

## Key Development Practices

### Code Organization

- **Separation of Concerns**: Core services (encryption, storage, blockchain) are isolated in `lib/core/`
- **State Management**: Riverpod providers for reactive state
- **Features**: Feature-specific UI and logic in `lib/features/`
- **Testing**: Move contracts tested with `sui move test`

### Security Guidelines

1. **Never commit secrets** — Use `.env.local` for sensitive data
2. **Secure storage** — Passphrases stored in `flutter_secure_storage`
3. **Key derivation** — PBKDF2 with 10k iterations for key derivation
4. **Encryption** — AES-256-GCM for all file encryption
5. **Network** — All Walrus/Sui connections use HTTPS/WSS

### Smart Contract Development

- **Move language**: Sui's safe language for blockchain logic
- **Timer logic**: Encoded directly in contract state
- **Events**: All state changes emit cryptographic events
- **Testing**: Full Move test suite for edge cases

### Build & Deployment

```bash
# Flutter
flutter pub get
flutter build ios / android

# Contracts
cd contracts && sui move build && sui move test && sui client publish
```

## File Structure Guidelines

```
app/lib/
├── core/              # Reusable services & providers
├── features/          # Feature-specific screens & logic
├── widgets/           # Reusable UI components
└── main.dart          # Entry point

contracts/
├── sources/           # Move contract files
└── tests/             # Move test modules
```

## Testing Requirements

- **Flutter**: Minimum 70% code coverage
- **Move**: All functions must have corresponding tests
- **Integration**: End-to-end tests for upload/retrieve flow

## Deployment Checklist

- [ ] All tests passing (Flutter + Move)
- [ ] No secrets in codebase
- [ ] Contract deployed to Sui testnet/mainnet
- [ ] Update package IDs in config
- [ ] Security audit of encryption implementation
- [ ] Load testing for concurrent uploads

---

**Last Updated**: May 2026
