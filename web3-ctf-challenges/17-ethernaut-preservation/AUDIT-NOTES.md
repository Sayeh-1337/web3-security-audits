# Audit Notes — `Preservation.sol`

**Auditor notes for:** Ethernaut 17 Preservation (CTF)  
**Contract:** `src/Preservation.sol`  
**Annotated copy:** `src/Preservation.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | `delegatecall` + mismatched library storage overwrites `timeZone1Library` / `owner` | `setFirstTime` / `LibraryContract` |

**Verdict:** Anyone can replace the library pointer, then claim ownership via a malicious `setTime`.

---

## Storage layouts

| Slot | `Preservation` | `LibraryContract` |
|------|----------------|-------------------|
| 0 | `timeZone1Library` | `storedTime` |
| 1 | `timeZone2Library` | — |
| 2 | `owner` | — |
| 3 | `storedTime` | — |

---

## Exploit path

1. `setFirstTime(uint256(uint160(evil)))` → writes slot 0 → `timeZone1Library = evil`
2. `setFirstTime(uint256(uint160(player)))` → evil `setTime` writes slot 2 → `owner = player`

---

## Auditor sign-off

| Item | Status |
|------|--------|
| PoC | `test/PreservationExploit.t.sol` |
| Safe library pattern | **No** — use matching storage / `library` keyword / diamond storage |
