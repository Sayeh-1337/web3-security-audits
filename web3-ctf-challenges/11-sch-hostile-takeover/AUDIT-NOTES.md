# Audit Notes — Hostile Takeover (Civic*)

**Auditor notes for:** SCH Bonus 11 Hostile Takeover  
**Contracts:** `CivicToken`, `CivicVault`, `CivicCustody`, `CivicCouncil`  
**Full writeup:** `WRITEUP.md`

---

## Audit summary

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| C-01 | **Critical** | Flash voting power via custody callback before restitution | `CivicCustody.checkout` + `CivicCouncil.propose` |
| I-01 | Info | Snapshot copies live balances — temporary holders get permanent proposal votes | `CivicToken.snapshot` / `propose` |
| I-02 | Info | `custody` immutable on council unused for access control | `CivicCouncil` |

**Verdict:** Not safe. Custody tokens can be used as instantaneous governance majority.

---

## Cross-contract flow (vulnerable)

```
checkout(amount)
  token.transfer(attacker, amount)          // attacker now has 2M CVC
  attacker.receiveCustody(amount)
      council.propose(player, 500 ETH)
          token.snapshot()                  // records attacker balance = 2M
          votes = balanceOfAt(attacker)     // 2M > 6M/4
      token.transfer(custody, amount)       // restitution
  require(custody balance restored)         // passes
execute(proposalId)
  vault.sendPayment(player, 500 ETH)        // drained
```

---

## CivicCustody.checkout

| Note | Detail |
|------|--------|
| **CRITICAL (C-01)** | External callback between transfer-out and restitution check. Same class as ERC-777/ERC-667 hooks and read-only reentrancy — here it is **governance power** reentrancy. |
| **OK** | Final `require` restores custody accounting — but does not undo side effects (proposals). |
| **FIX** | Snapshot/vote only with locked stake; or disallow arbitrary calls during checkout; or use checks-effects-interactions with votes based on custody-locked balances. |

---

## CivicCouncil.propose / execute

| Note | Detail |
|------|--------|
| **CRITICAL** | Votes frozen at propose-time from a live balance snapshot — no requirement tokens stay locked. |
| **INFO** | Threshold `votes > totalSupply/4` is reachable with custody's 2M of 6M. |
| **FIX** | Require tokens locked until execute; or vote from escrowed weight, not flash balances. |

---

## CivicVault / CivicToken

| Note | Detail |
|------|--------|
| **OK** | Vault correctly gated by governance. |
| **OK** | Token mint onlyOwner; snapshot is complete for small holder sets. |
| **INFO** | Trusting vault `sendPayment` after broken governance is the impact amplifier. |

---

## Remediation priority

1. **C-01** — Do not allow governance actions (or any lasting side effect) while custody tokens are checked out; or credit voting power only for tokens locked in a staking module.
2. Consider separating “custody flash loan” from governance token, or using a non-voting receipt token for temporary checkout.

---

## Auditor sign-off

| Item | Status |
|------|--------|
| Callback / CEI across modules | Done — C-01 |
| Governance threshold math | Done — 2M > 1.5M |
| Exploit PoC | `test/HostileTakeoverExploit.t.sol` |
| Safe to deploy | **No** |
