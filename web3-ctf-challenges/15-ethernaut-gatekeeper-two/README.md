# 15 — Ethernaut Gatekeeper Two

- Challenge: [Gatekeeper Two](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-gatekeeper-two)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Set the player as `entrant`.

## Starting facts

- **gateOne:** need a contract caller (`msg.sender != tx.origin`)
- **gateTwo:** `extcodesize(caller()) == 0` — call from **constructor**
- **gateThree:** `key = ~uint64(bytes8(keccak256(abi.encodePacked(helper))))`

## Files

| File | Purpose |
|------|---------|
| `src/GatekeeperTwo.sol` | Target contract |
| `src/GatekeeperTwo.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/GatekeeperTwoExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
