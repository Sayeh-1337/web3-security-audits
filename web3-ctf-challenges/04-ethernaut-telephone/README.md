# 04 — Ethernaut Telephone

- Challenge: [Telephone](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-telephone)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Change the Telephone `owner` to the player address.

## Starting facts

- `owner` = factory / deployer
- `changeOwner` only succeeds when `tx.origin != msg.sender`
- Direct EOA call fails the check; a middleman contract passes it

## Files

| File | Purpose |
|------|---------|
| `src/Telephone.sol` | Target contract (unmodified SCH version) |
| `src/Telephone.annotated.sol` | Same contract with inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes and findings register |
| `Exploit.s.sol` | SCH submission snippet (HelperContract + run) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/TelephoneExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution steps |

## Local test

```bash
forge test --match-test testExploit -vv
```
