# Audit Notes — `AlienCodex.sol`

**Auditor notes for:** Ethernaut 20 Alien Codex (CTF)  
**Contract:** `src/AlienCodex.sol` (local) / `reference/AlienCodex.0.5.sol` (SCH 0.5)  
**Annotated copy:** `src/AlienCodex.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Dynamic array length underflow → arbitrary storage write | `retract` + `revise` |

**Verdict:** Become owner by mapping `codex[i]` onto slot 0 after underflowing length.

---

## Storage layout

| Slot | Content |
|------|---------|
| 0 | `owner` (addr) + `contact` (bool), packed |
| 1 | `codex.length` |
| `keccak256(1) + i` | `codex[i]` |

Target index for slot 0: `i = -keccak256(abi.encode(1))` (mod 2^256).

---

## Exploit path

1. `makeContact()` — pass `contacted` modifier
2. `retract()` — length → `type(uint256).max`
3. `revise(index, bytes32(uint256(uint160(player))))` — overwrite owner

---

## Auditor sign-off

| Item | Status |
|------|--------|
| PoC | `test/AlienCodexExploit.t.sol` |
| Safe pattern | Use Solidity ≥0.8 / `pop()`; never expose raw length writes |
