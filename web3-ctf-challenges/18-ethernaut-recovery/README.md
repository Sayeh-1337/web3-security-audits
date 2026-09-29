# 18 — Ethernaut Recovery

- Challenge: [Recovery](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-recovery)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)

## Goals

1. Recover the Ether sent to the generated `SimpleToken` contract.

## Starting facts

- `Recovery.generateToken` deploys `SimpleToken` with `new` but never stores the address
- The token owner is whoever called `generateToken` (`msg.sender` in the constructor)
- Derive the token address with CREATE RLP (do **not** use `vm.computeCreateAddress` on SCH):
  `keccak256(0xd6 || 0x94 || recovery || 0x01)[12:]`
- First child from a fresh `Recovery` uses deployer nonce **1**

## Files

| File | Purpose |
|------|---------|
| `src/Recovery.sol` | Target + token contracts |
| `src/Recovery.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Line-by-line audit notes |
| `Exploit.s.sol` | SCH submission snippet |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/RecoveryExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
