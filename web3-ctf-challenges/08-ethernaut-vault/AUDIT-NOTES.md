# Audit Notes — `Vault.sol`

**Auditor notes for:** Ethernaut 08 Vault (CTF)  
**Contract:** `src/Vault.sol`  
**Annotated copy:** `src/Vault.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Secret stored in cleartext contract storage (`private` ≠ confidential) | L6, L8–11 |
| I-01 | Info | Password also recoverable from constructor calldata / tx history | constructor |

**Verdict:** Not suitable for protecting real secrets. Anyone can read slot 1 and unlock.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| Storage visibility / `private` semantics | Encryption / ZK secret schemes (remediation options) |

---

## Line-by-line review

### State layout

| Slot | Variable | Visibility |
|------|----------|------------|
| 0 | `bool locked` | public |
| 1 | `bytes32 password` | private |

`bytes32` needs a full slot, so `locked` is not packed with it.

### `password` + `unlock`

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | `private` blocks Solidity getters / other contracts — not RPC `eth_getStorageAt`. |
| **INFO (I-01)** | Constructor arg is in the deployment transaction forever. |
| **FIX** | Do not put secrets on-chain. Use commit-reveal, off-chain auth, or ZK proofs. Hashing alone is insufficient if the preimage was ever submitted on-chain. |

---

## Attack path

```
vm.load(vault, slot 1)  →  password
vault.unlock(password)  →  locked = false
```

---

## Remediation

1. Never store plaintext secrets in contract storage.
2. If a unlock key is required, keep it off-chain and use signatures / oracles / ZK.
3. Educate: `private` is an access modifier for the ABI, not cryptography.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| Storage slots mapped | Done — password @ 1 |
| Exploit PoC | `test/VaultExploit.t.sol` |
| Safe for real secrets | **No** |
