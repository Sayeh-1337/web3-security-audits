# 06 — Ethernaut Delegation

- Challenge: [Delegation](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-delegation)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Claim ownership of the `Delegation` contract.

## Starting facts

- `Delegation.fallback` forwards all `msg.data` via `delegatecall` to `Delegate`
- `Delegate.pwn()` sets `owner = msg.sender` with no access control
- Both contracts store `owner` in slot 0 → `pwn()` overwrites `Delegation.owner`
- `msg.sender` is preserved under `delegatecall` (player EOA)

## Files

| File | Purpose |
|------|---------|
| `src/Delegation.sol` | Target (`Delegate` + `Delegation`) |
| `src/Delegation.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/DelegationExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
