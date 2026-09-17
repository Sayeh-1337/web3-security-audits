# 11 — SCH Hostile Takeover

- Challenge: [Hostile Takeover](https://smartcontractshacking.com/tools/web3-ctf-challenges/sch-hostile-takeover)
- Platform: SCH Original (Bonus)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Move all ETH held by `CivicVault` to the player address.
2. Leave `CivicCustody`'s CVC balance unchanged.

## Starting facts

- CivicVault balance: **500 ETH**
- CivicCustody balance: **2,000,000 CVC**
- Total supply: **6,000,000 CVC**
- Execute threshold: votes **> 25%** of supply at snapshot (`> totalSupply / 4`)

## Bug (short)

`CivicCustody.checkout` transfers tokens to a contract and calls `receiveCustody` **before** requiring restitution. During that callback you still hold the tokens, so `CivicCouncil.propose` snapshots **>25%** voting power. Return the CVC, then `execute` drains the vault. Custody CVC ends unchanged.

## Files

| File | Purpose |
|------|---------|
| `src/CivicToken.sol` | Snapshot ERC20-like token |
| `src/CivicVault.sol` | ETH treasury (governance-gated) |
| `src/CivicCustody.sol` | Flash checkout with restitution check |
| `src/CivicCouncil.sol` | Propose / execute governance |
| `AUDIT-NOTES.md` | Cross-contract audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Local Foundry script |
| `test/HostileTakeoverExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Full analysis |

## Local test

```bash
forge test --match-test testExploit -vv
```
