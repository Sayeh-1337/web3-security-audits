# Audit Notes — `MagicNumber.sol`

**Auditor notes for:** Ethernaut 19 MagicNumber (CTF)  
**Contract:** `src/MagicNumber.sol`  
**Annotated copy:** `src/MagicNumber.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| I-01 | **Info** | Unrestricted `setSolver` — any bytecode may be registered | `setSolver` |
| I-02 | **Info** | Level constraint (≤10 runtime bytes) is off-chain only | verifier |

**Verdict:** Intended CTF design — learners hand-craft EVM bytecode that returns `42` in ≤10 bytes.

---

## Runtime bytecode (10 bytes)

| Bytes | Opcode | Meaning |
|-------|--------|---------|
| `60 2a` | PUSH1 42 | value |
| `60 00` | PUSH1 0 | memory offset |
| `52` | MSTORE | write 32-byte word ending in 42 |
| `60 20` | PUSH1 32 | return length |
| `60 00` | PUSH1 0 | return offset |
| `f3` | RETURN | ABI-encode `uint256(42)` |

Full creation+runtime: `600a600c600039600a6000f3602a60005260206000f3`

---

## Exploit path

1. `create` the bytecode above → solver address
2. `magicNumberInstance.setSolver(solver)`

---

## Auditor sign-off

| Item | Status |
|------|--------|
| PoC | `test/MagicNumberExploit.t.sol` |
| Size check on-chain | **No** — enforce in factory/verifier if required in production |
