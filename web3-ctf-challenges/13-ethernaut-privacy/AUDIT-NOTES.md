# Audit Notes — `Privacy.sol`

**Auditor notes for:** Ethernaut 13 Privacy (CTF)  
**Contract:** `src/Privacy.sol`  
**Annotated copy:** `src/Privacy.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Cleartext secret in `private` storage (`data[2]` @ slot 5) | L10–17 |
| I-01 | Info | Packing in slot 2 is correct but irrelevant to the key | L7–9 |

**Verdict:** Not suitable for protecting secrets. Anyone can read slot 5 and unlock.

---

## Storage layout

| Slot | Variable |
|------|----------|
| 0 | `locked` |
| 1 | `ID` |
| 2 | `flattening` + `denomination` + `awkwardness` |
| 3 | `data[0]` |
| 4 | `data[1]` |
| 5 | `data[2]` |

`bytes16(data[2])` keeps the **high-order** 16 bytes of the word.

---

## `unlock`

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | Compares against on-chain private storage. `private` ≠ confidential. |
| **FIX** | Do not store unlock secrets on-chain. Use signatures / off-chain auth / ZK. |

---

## Auditor sign-off

| Item | Status |
|------|--------|
| Slots mapped | Done — key @ 5 |
| Exploit PoC | `test/PrivacyExploit.t.sol` |
| Safe for real secrets | **No** |
