# 21 — Ethernaut Denial

- Challenge: [Denial](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-denial)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Make Denial's owner withdrawal fail within a bounded gas budget.

## Starting facts

- `setWithdrawPartner` has **no access control** — anyone can set `partner`
- `withdraw` does `partner.call{value: ...}("")` with almost all remaining gas, then `owner.transfer`
- Partner can burn that gas so `owner.transfer` cannot complete under the verifier’s gas cap

## Files

| File | Purpose |
|------|---------|
| `src/Denial.sol` | Target contract |
| `src/Denial.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/DenialExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
