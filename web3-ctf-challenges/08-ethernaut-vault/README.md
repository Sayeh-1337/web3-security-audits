# 08 — Ethernaut Vault

- Challenge: [Vault](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-vault)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Unlock the Vault (`locked == false`).

## Starting facts

- `locked` is public (slot 0)
- `password` is `private` (slot 1) — still readable on-chain
- `unlock(password)` sets `locked = false` on match

## Files

| File | Purpose |
|------|---------|
| `src/Vault.sol` | Target contract (unmodified SCH version) |
| `src/Vault.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/VaultExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
