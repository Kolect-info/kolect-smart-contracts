# Kolect Daily Check-In Points

The **Kolect Daily Check-In Points** contract implements a simple on-chain daily participation system.

Each wallet address can perform **one check-in every 24 hours**, accumulating non-transferable points that reflect long-term engagement with the Kolect platform.

---

## Contract Overview

- **Contract Name:** KolectDailyCheckIn  
- **Version:** v1.0.0  
- **License:** MIT  
- **Solidity Version:** >=0.8.20 <0.9.0  

This contract is designed to be minimal, transparent, and easy to integrate.
All state is stored fully on-chain and can be independently verified via public block explorers.

---

## Core Mechanics

### Daily Check-In
- Users call `checkIn()` to record a check-in.
- Each address can only check in once per 24-hour period.
- First-time users can check in immediately.
- A successful check-in increases the user’s point balance by **1**.

### Points
- Points are **non-transferable**.
- Points can only increase through valid check-ins.
- Points are intended to represent participation only and have no financial meaning.

### Time Enforcement
- A fixed 24-hour interval is enforced between check-ins.
- The contract stores the timestamp of the last successful check-in for each address.

---

## Public View Functions

The following read-only functions are provided for integration and analytics:

- `canCheckIn(address user)`  
  Returns whether the user can check in at the current block timestamp.

- `nextCheckInTime(address user)`  
  Returns the earliest timestamp at which the user can next check in.

- `getPoints(address user)`  
  Returns the total number of points accumulated by the user.

- `getLastCheckIn(address user)`  
  Returns the timestamp of the user’s last check-in.

---

## Events

```solidity
event CheckedIn(address indexed user, uint256 timestamp, uint256 totalPoints);
```

Emitted each time a user successfully checks in.

---

## Administrative Controls

The contract uses OpenZeppelin’s `Ownable` and `Pausable` modules.

- `pause()`  
  Pauses the check-in functionality.

- `unpause()`  
  Resumes the check-in functionality.

Ownership cannot be renounced.
The `renounceOwnership()` function is intentionally disabled to prevent the contract from becoming permanently ownerless.

---

## Audit

This contract has been audited by **SlowMist**.

- **Auditor:** SlowMist  
- **Scope:** Kolect Daily Check-In Points smart contract  
- **Audit Report:**  
```
/audit/SlowMist_Audit_Report.pdf
```

---

## Deployed Contracts

Each deployment is functionally identical and independently verifiable on its respective network.

| Network | Contract Address | Block Explorer |
|--------|------------------|----------------|
| Ethereum Mainnet | `0x6783ab3c181976e8c960c43d711aaf4da79a4e4b` | https://etherscan.io/address/0x6783ab3c181976e8c960c43d711aaf4da79a4e4b |
| Arbitrum One | `0xf5b88904c241fbb516d9b2ad8553c15e55e14307` | https://arbiscan.io/address/0xf5b88904c241fbb516d9b2ad8553c15e55e14307 |
| BNB Smart Chain | `0xf5b88904c241fbb516d9b2ad8553c15e55e14307` | https://bscscan.com/address/0xf5b88904c241fbb516d9b2ad8553c15e55e14307 |
| Base | `0xf5b88904C241fbB516d9B2ad8553c15E55e14307` | https://base.blockscout.com/address/0xf5b88904C241fbB516d9B2ad8553c15E55e14307 |

---

## 📊 Analytics & Dashboard

On-chain activity data for the Kolect Daily Check-In contract is publicly available via Dune Analytics:

👉 **Dune Dashboard:** https://dune.com/kolect/kolect-daily-checkin

The dashboard currently tracks and visualizes the following metrics:

1. **Total Check-In Count**  
   The cumulative number of check-in events recorded on-chain.

2. **Total Unique Wallets**  
   The total number of distinct wallet addresses that have performed at least one check-in.

3. **Unique Wallets Over Time**  
   A time-series view showing the growth of unique participating wallets.

4. **Daily Check-In Events by Blockchain**  
   The daily number of Kolect check-in events on each supported blockchain network.

5. **Kolect Check-In Wallet Leaderboard**  
   A leaderboard ranking wallets by total accumulated check-in count.

All metrics are derived directly from on-chain `CheckedIn` events emitted by the deployed contract instances.

---

## Source Code

The contract source code is located at:

```
/contracts/KolectDailyCheckIn.sol
```

---

## Disclaimer

This contract records participation points only.

Points are non-transferable, have no monetary value, and do not represent ownership, equity, or any financial rights.
