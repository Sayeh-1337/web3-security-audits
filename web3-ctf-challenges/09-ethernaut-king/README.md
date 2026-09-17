# 09 — Ethernaut King

- Challenge: [King](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-king)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Become king and prevent the level owner from reclaiming the throne.

## Starting facts

- Deployed with a prize (typically `0.001 ether`)
- New king must send `msg.value >= prize` (owner can bypass prize check)
- Previous king is paid via `.transfer` before the new king is set
- A contract king with no payable `receive`/`fallback` makes that transfer revert → permanent DoS

## Files

| File | Purpose |
|------|---------|
| `src/King.sol` | Target contract (unmodified SCH version) |
| `src/King.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet (HelperContract + run) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/KingExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
