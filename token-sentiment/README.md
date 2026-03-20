# Kolect Sentiment Feed

## Overview

Kolect Sentiment Feed is an on-chain sentiment oracle designed for the Kolect ecosystem.

It records and serves normalized market sentiment data for supported trading symbols and time windows, enabling verifiable, transparent, and composable sentiment signals for on-chain applications.

The system follows a request–response architecture:
- Users request sentiment updates on-chain
- An off-chain publisher fetches data from the Kolect Sentiment API
- The publisher fulfills the request and stores the result on-chain

This design bridges off-chain intelligence with on-chain verifiability.

---

## Key Features

### On-chain Sentiment Oracle
- Stores normalized sentiment data (negative / neutral / positive)
- Uses basis points (BPS) format (sum = 10,000)
- Supports multiple symbols and time windows

### Request-Based Updates
- Users trigger updates via `requestUpdate`
- Prevents redundant updates with freshness checks
- Ensures efficient and demand-driven data updates

### Verifiable Data Pipeline
- All updates are recorded on-chain
- Full transparency of:
  - who requested
  - when it was fulfilled
  - what data was published

### Configurable Market Coverage
- Dynamic support for:
  - trading symbols (e.g. BTC, ETH)
  - time windows (e.g. 1h, 1d)
- Adjustable update intervals per time window

### Economic Layer
- Request fee mechanism
- Enables sustainable oracle operation
- Allows demand-driven data provisioning

---

## Contract Information

| Field | Value |
|------|------|
| Project | Kolect |
| Module | Kolect Sentiment Feed |
| Version | v1.0.0 |
| Website | https://kolect.info |
| Twitter | https://x.com/kolect_info |
| Network | Base |
| Contract Address | `0x6783ab3c181976e8c960c43d711aaf4da79a4e4b` |
| Explorer | https://base.blockscout.com/address/0x6783ab3c181976e8c960c43d711aaf4da79a4e4b |

---

## Data Model

Each sentiment feed is defined by:

`(symbol, timeWindow)`

Example:

`(BTC, 1d)`  
`(ETH, 1h)`

Each feed stores:

- `negativeBps`
- `neutralBps`
- `positiveBps`
- `dataTimestamp` (off-chain data time)
- `updatedAt` (on-chain update time)

Constraint:

`negative + neutral + positive = 10000 (BPS)`

---

## How It Works

### 1. Request Update

Users call:

`requestUpdate(symbol, timeWindow)`

Conditions:
- Symbol must be supported
- Time window must be supported
- Feed must not be fresh
- No pending request exists
- Fee must be paid

---

### 2. Off-chain Processing

The publisher:
- listens to `UpdateRequested`
- fetches sentiment from Kolect API
- prepares normalized BPS data

---

### 3. Fulfillment

Publisher calls:

`fulfillRequest(requestId, negativeBps, neutralBps, positiveBps, dataTimestamp)`

Result:
- Data stored on-chain
- Request marked as fulfilled
- Event emitted

---

### 4. Failure Handling

If data retrieval fails:

`failRequest(requestId, errorCode)`

---

## Core Functions

### User

`requestUpdate(string symbol, string timeWindow)`

---

### Publisher

`fulfillRequest(...)`  
`failRequest(...)`

---

### View

`getLatest(symbol, timeWindow)`  
`isFresh(symbol, timeWindow)`  
`hasPendingRequest(symbol, timeWindow)`

---

### Owner

`setSupportedSymbol(...)`  
`setSupportedTimeWindow(...)`  
`setUpdateInterval(...)`  
`setRequestFee(...)`  
`withdrawFees(...)`

---

## Events

Key events for indexing (Dune / Subgraph):

- `UpdateRequested`
- `RequestFulfilled`
- `RequestFailed`

---

## Design Principles

### Transparency
All sentiment updates are publicly verifiable on-chain.

### Demand-Driven
Data is updated only when requested, optimizing cost and efficiency.

### Composability
The feed can be integrated into:
- trading strategies
- DeFi protocols
- analytics dashboards
- AI agents

### Reliability
- freshness checks
- pending request control
- strict data validation

---

## Use Cases

- Sentiment-based trading strategies
- Market regime detection
- DeFi risk signals
- AI-driven execution systems
- Research and analytics

---

## Contact

- Website: https://kolect.info
- Twitter: https://x.com/kolect_info
