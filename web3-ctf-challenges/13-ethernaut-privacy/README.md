# 13 — Ethernaut Privacy

- Challenge: [Privacy](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-privacy)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Unlock the Privacy contract (`locked == false`).

## Starting facts

- `private` storage is still readable on-chain
- Key is `bytes16(data[2])`
- `data[2]` is in **storage slot 5**

### Storage layout

| Slot | Content |
|------|---------|
| 0 | `locked` |
| 1 | `ID` |
| 2 | packed `flattening`, `denomination`, `awkwardness` |
| 3 | `data[0]` |
| 4 | `data[1]` |
| 5 | `data[2]` (key source) |

## Files

| File | Purpose |
|------|---------|
| `src/Privacy.sol` | Target contract |
| `src/Privacy.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/PrivacyExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
