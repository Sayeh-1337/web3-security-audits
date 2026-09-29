# 17 — Ethernaut Preservation

- Challenge: [Preservation](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-preservation)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Become the owner of the Preservation contract.

## Starting facts

- `setFirstTime` / `setSecondTime` use `delegatecall` into libraries
- Library `storedTime` is slot 0 → collides with `timeZone1Library`
- Replace library with a malicious contract, then overwrite `owner` (slot 2)

## Files

| File | Purpose |
|------|---------|
| `src/Preservation.sol` | Target + library contracts |
| `src/Preservation.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/PreservationExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
