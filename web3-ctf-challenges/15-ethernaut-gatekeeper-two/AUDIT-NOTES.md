# Audit Notes — `GatekeeperTwo.sol`

**Auditor notes for:** Ethernaut 15 Gatekeeper Two (CTF)  
**Contract:** `src/GatekeeperTwo.sol`  
**Annotated copy:** `src/GatekeeperTwo.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| H-01 | High | `gateOne` only checks contract vs EOA | `gateOne` |
| C-01 | **Critical** | `extcodesize == 0` is true during construction | `gateTwo` |
| C-02 | **Critical** | XOR key fully determined by `msg.sender` | `gateThree` |

**Verdict:** All three gates bypassable via constructor call + XOR key of the helper address.

---

## Gate breakdown

| Gate | Check | Bypass |
|------|-------|--------|
| One | `msg.sender != tx.origin` | Call from a contract |
| Two | `extcodesize(caller()) == 0` | Call `enter` from that contract's **constructor** |
| Three | `hash(msg.sender) ^ key == uint64.max` | `key = ~uint64(bytes8(keccak256(abi.encodePacked(address(this)))))` |

---

## Auditor sign-off

| Item | Status |
|------|--------|
| Constructor + XOR PoC | `test/GatekeeperTwoExploit.t.sol` |
| Safe access control | **No** — code-size and bitwise puzzles ≠ auth |
