# Audit Notes — `GatekeeperOne.sol`

**Auditor notes for:** Ethernaut 14 Gatekeeper One (CTF)  
**Contract:** `src/GatekeeperOne.sol`  
**Annotated copy:** `src/GatekeeperOne.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| H-01 | High | `gateOne` only checks contract vs EOA — intermediate caller bypasses | L7–10 |
| H-02 | High | `gateTwo` gas constraint is brute-forceable | L12–15 |
| C-01 | **Critical** | `gateThree` key is a deterministic mask of `tx.origin` | L17–22 |

**Verdict:** All three gates are bypassable. Entrant can be set to any EOA that calls via a helper with the right key and gas.

---

## Gate breakdown

| Gate | Check | Bypass |
|------|-------|--------|
| One | `msg.sender != tx.origin` | Call through `HelperContract` |
| Two | `gasleft() % 8191 == 0` | Brute `call{gas: base+i}` for `i ∈ [0, 8190]` |
| Three | Key bit constraints vs `tx.origin` | `bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF)` |

---

## `gateThree` bit layout (bytes8 / uint64)

```
[63........32][31..16][15.....0]
   non-zero      0x0000   == uint16(tx.origin)
```

---

## Auditor sign-off

| Item | Status |
|------|--------|
| Key formula | Done |
| Gas brute-force PoC | `test/GatekeeperOneExploit.t.sol` |
| Safe access control pattern | **No** — gas + origin-derived “keys” are not auth |
