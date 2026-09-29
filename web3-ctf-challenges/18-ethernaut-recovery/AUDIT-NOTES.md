# Audit Notes — `Recovery.sol`

**Auditor notes for:** Ethernaut 18 Recovery (CTF)  
**Contract:** `src/Recovery.sol`  
**Annotated copy:** `src/Recovery.annotated.sol`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| M-01 | **Medium** | Deployed token address not recorded (CREATE address must be derived) | `generateToken` |
| I-01 | **Info** | ETH recovery only via owner `selfdestruct` | `SimpleToken.destroy` |

**Verdict:** Intended CTF design — learners derive CREATE address and call `destroy` as token owner.

---

## CREATE address (first `SimpleToken`)

| Field | Value |
|-------|--------|
| Deployer | `address(recoveryInstance)` |
| Nonce | `1` (first contract creation from a new contract account) |
| Formula | `address(uint160(uint256(keccak256(RLP([deployer, nonce])))))` |

Manual RLP (SCH-safe; no `vm.computeCreateAddress`):

```solidity
keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(recoveryInstance), bytes1(0x01)))
```

---

## Exploit path

1. Level already has a `SimpleToken` (player is `owner` / creator).
2. Derive address with RLP CREATE math (nonce `1`).
3. `SimpleToken(token).destroy(payable(player))` — sends balance to player.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| PoC | `test/RecoveryExploit.t.sol` |
| Address discoverability | **Poor** — emit `TokenCreated` or store mapping for production |
