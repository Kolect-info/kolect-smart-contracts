# Kolect Smart Contracts

This repository is used to store and maintain smart contract code related to **Kolect**.

The contracts in this repository are maintained and updated over time as Kolect's products and on-chain features evolve.
They support various on-chain functionalities used by the Kolect platform.

Only contracts that are publicly released or deployed are included in this repository, along with relevant documentation for reference and review.

---

## Repository Structure

```
.
├── README.md
├── daily-check-in
│   ├── contracts
│   ├── audit
│   └── README.md
└── token-sentiment
    ├── SentimentOracle.sol
    └── README.md
```

- Each contract module is organized in its own directory.
- Source code, audit reports, and module-level documentation are grouped together for clarity.

---

## Modules

### Daily Check-In

An on-chain daily participation contract that allows users to check in once every 24 hours and accumulate non-transferable points.

- Directory: `daily-check-in/`
- Includes contract source, audit report, and module documentation
- Currently deployed across Ethereum, Arbitrum, BNB Smart Chain, and Base

### Token Sentiment Feed

An on-chain sentiment oracle for the Kolect ecosystem that stores normalized market sentiment data for supported trading symbols and time windows.

- Directory: `token-sentiment/`
- Includes contract source and module documentation
- Currently deployed on Base

---

## Links

- Website: https://kolect.info
- X (Twitter): https://x.com/kolect_info

---

## Network Support

Kolect smart contracts in this repository currently include deployments on:

- Ethereum
- Arbitrum
- BNB Smart Chain (BSC)
- Base

---

## Disclaimer

The smart contracts in this repository are provided for transparency and public review purposes only.
They do not constitute financial advice, investment advice, or any form of solicitation.
