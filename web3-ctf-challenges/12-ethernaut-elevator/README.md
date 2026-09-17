# 12 — Ethernaut Elevator

- Challenge: [Elevator](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-elevator)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Make `Elevator.top() == true`.

## Starting facts

- `goTo` treats `msg.sender` as a `Building`
- `isLastFloor` is called **twice** and is **not** `view`
- A malicious building can return `false` then `true`

## Files

| File | Purpose |
|------|---------|
| `src/Elevator.sol` | Target contract (unmodified SCH version) |
| `src/Elevator.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/ElevatorExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
