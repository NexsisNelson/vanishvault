# Contributing to VanishVault

Thank you for your interest in contributing to VanishVault! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Focus on the code, not the person
- Help others learn and grow
- Report issues privately to maintainers

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/vanishvault.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Setup

### Flutter Development

```bash
cd app
flutter pub get
dart run build_runner build
```

### Sui Development

```bash
cd contracts
sui move build
sui move test
```

## Code Style

### Dart/Flutter

- Follow [Google's Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` for formatting
- Use `flutter analyze` for linting
- Maximum line length: 100 characters

```bash
flutter format lib/
flutter analyze
```

### Move

- Follow Sui Move conventions
- Use descriptive names
- Document public functions
- Include tests for all functions

## Testing

### Flutter Tests

```bash
flutter test
flutter test --coverage
```

Minimum coverage: 70%

### Move Tests

```bash
cd contracts
sui move test
```

All functions must have corresponding tests.

### Integration Tests

```bash
flutter test integration_test/
```

## Commit Messages

Use clear, descriptive commit messages:

```
feat: Add file upload with progress tracking
fix: Resolve encryption timeout issue
docs: Update API reference
test: Add tests for Walrus service
refactor: Extract encryption logic to separate class
```

Format: `type: description`

Types:
- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation
- `test` — Tests
- `refactor` — Code refactoring
- `chore` — Build, CI/CD
- `perf` — Performance improvement

## Pull Request Process

1. Update README.md with any new features
2. Ensure all tests pass
3. Update documentation as needed
4. Add a clear description of changes
5. Link to related issues
6. Request review from maintainers

## Reporting Issues

### Bug Reports

Include:
- Device and Flutter version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Logs/error messages

### Feature Requests

Include:
- Clear description of feature
- Use case/motivation
- Proposed implementation (optional)
- Related issues

## Security Issues

**Do not create public issues for security vulnerabilities!**

Email security details to: `security@vanishvault.dev`

## Documentation

- Update README.md for user-facing changes
- Update API.md for API changes
- Add comments for complex logic
- Keep docs in sync with code

## Licensing

By contributing, you agree that your contributions are licensed under the MIT License.

---

Thank you for contributing to VanishVault!
