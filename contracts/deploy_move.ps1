# PowerShell script to build and publish the Move contracts to Sui
# Usage: .\deploy_move.ps1 -Network testnet

param(
  [string]$Network = 'testnet'
)

Write-Host "Building Move contracts..."
cd contracts

# Build
sui move build

Write-Host "Running tests..."
sui move test

Write-Host "Publishing to $Network..."
# For publish to testnet/mainnet, run with appropriate RPC and signer configured
sui client publish --network $Network

Write-Host "After publishing, update app/lib/core/config.dart -> EnvironmentConfig.packageId"
