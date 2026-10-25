# 20 — Ethernaut Alien Codex

- Challenge: [Alien Codex](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-alien-codex)
- Platform: Ethernaut (SCH)
- Reward: 100 EXP (Junior Hacker)
- Note: SCH runs Solidity **0.5** (`AlienScript.sol`); local lab ports `retract` with assembly for 0.8 Foundry.

## Goals

1. Overwrite Alien Codex's `owner` with the player address.

## Starting facts

- Storage: slot 0 = `owner` + `contact` (packed); slot 1 = `codex.length`
- `codex[i]` data at `keccak256(1) + i`
- Solidity 0.5: `codex.length--` underflows to `2^256 - 1`
- Then `revise` can write any slot — including slot 0 (`owner`)

## Files

| File | Purpose |
|------|---------|
| `src/AlienCodex.sol` | Local 0.8 target (assembly underflow) |
| `reference/AlienCodex.0.5.sol` | SCH / Ethernaut 0.5 source (reference) |
| `src/AlienCodex.annotated.sol` | Inline `AUDIT:` comments |
| `AUDIT-NOTES.md` | Audit notes |
| `Exploit.s.sol` | SCH submission snippet (0.5-safe) |
| `script/Exploit.s.sol` | Full local Foundry script |
| `test/AlienCodexExploit.t.sol` | Local exploit test |
| `WRITEUP.md` | Vulnerability analysis + solution |

## Local test

```bash
forge test --match-test testExploit -vv
```
