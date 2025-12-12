# EES Periphery

EES (Ethereum Execution Service) is an open protocol for on-chain automation. Developers can create applications on top of EES which benefit from timely execution. Automation is achieved by opening execution up to the public through financial incentivization.

**⚠️ WARNING: This code has not been audited. Use at your own risk.**

## Overview

This repository contains the periphery contracts for the EES protocol, including query utilities, batch operations, configuration providers, and price oracles.

## Components

### Core Contracts

- **BatchSlasher**: Enables batch slashing of executors (both inactive and committer executors) in a single transaction
- **Querier**: Provides comprehensive querying functionality for jobs, executors, commitments, and epoch information
- **ConfigProvider**: Aggregates and provides configuration data from JobRegistry and Coordinator contracts

### Price Oracles

- **ChainlinkOracle**: Price oracle implementation using Chainlink price feeds to calculate token prices relative to ETH and USD
- **UniswapV2Oracle**: Price oracle implementation using Uniswap V2 pair cumulative prices

## Features

- Creation and managing of a job with a specific application, execution module and fee module
- Batch operations for efficient executor management
- Comprehensive querying interface for protocol state
- Multiple price oracle implementations for flexible fee calculations
- Centralized configuration provider for easy integration

## Deployed Contracts (Base Mainnet)

The following contracts are deployed on Base mainnet:

- **BatchSlasher**: [`0xe9De84f99fc5933003555b35067B4cCCD52fdB9D`](https://basescan.org/address/0xe9De84f99fc5933003555b35067B4cCCD52fdB9D)
- **Querier**: [`0x9674071C70CE76Eb22CDC26AEECdd18E9F317834`](https://basescan.org/address/0x9674071C70CE76Eb22CDC26AEECdd18E9F317834)
- **ConfigProvider**: [`0xEA54BF6071b4aE4b94F359F17e18ff16eDB173b3`](https://basescan.org/address/0xEA54BF6071b4aE4b94F359F17e18ff16eDB173b3)

## Documentation

For more information about the EES protocol, visit [https://docs.ees.xyz](https://docs.ees.xyz).

## Security

**⚠️ WARNING: This code has not been audited. Use at your own risk.**

The code is being built in public and has not yet undergone a security audit. Users should exercise caution and perform their own due diligence before interacting with these contracts.

## License

MIT 