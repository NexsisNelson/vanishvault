#!/usr/bin/env bash
set -euo pipefail

echo "Building Move contracts..."
cd "$(dirname "$0")"

echo "sui move build"
sui move build

echo "sui move test"
sui move test

echo "Publishing to testnet (adjust as needed)"
sui client publish --network testnet

echo "Done. Update app/lib/core/config.dart -> EnvironmentConfig.packageId with the deployed package ID"
