# Audit Notes — `NaughtCoin.sol`

**Auditor notes for:** Ethernaut 16 Naught Coin (CTF)  
**Contract:** `src/NaughtCoin.sol`  
**Annotated copy:** `src/NaughtCoin.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Time lock only on `transfer`; `approve`/`transferFrom` unrestricted | `transfer` / `transferFrom` |

**Verdict:** Incomplete lock. Player drains balance via allowance path before `timeLock`.

---

## Transfer surface

| Function | Time-locked? | Notes |
|----------|--------------|-------|
| `transfer` | Yes | `block.timestamp > timeLock` |
| `approve` | No | Sets allowance freely |
| `transferFrom` | No | Moves tokens if allowance set |

---

## Exploit path

1. `approve(helper, balanceOf(player))`
2. `helper.transferFrom(player, helper, balance)`

---

## Auditor sign-off

| Item | Status |
|------|--------|
| PoC | `test/NaughtCoinExploit.t.sol` |
| Safe vesting/lock pattern | **No** — lock every balance-changing path |
