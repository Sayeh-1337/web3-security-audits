# 14 — Ethernaut Gatekeeper One

- Challenge: [Gatekeeper One](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-gatekeeper-one)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Pass all three gates and set the player as `entrant`.

## Starting facts

- **gateOne:** need a contract caller (`msg.sender != tx.origin`)
- **gateTwo:** `gasleft() % 8191 == 0` — brute-force gas
- **gateThree:** key = `bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF)`

## Files

| File | Purpose |
|------|---------|
| `src/GatekeeperOne.sol` | Target contract |
| `src/GatekeeperOne.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/GatekeeperOneExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
