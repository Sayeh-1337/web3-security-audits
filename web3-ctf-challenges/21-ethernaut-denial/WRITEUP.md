# Denial — Security Writeup

| | |
|---|---|
| **Challenge** | [Ethernaut 21 — Denial](https://smartcontractshacking.com/tools/web3-ctf-challenges/ethernaut-denial) |
| **Platform** | Smart Contracts Hacking (SCH) / OpenZeppelin Ethernaut |
| **Target** | `src/Denial.sol` |
| **Solidity** | `^0.8.0` |
| **Severity** | Medium (DoS / gas griefing CTF) |
| **Status** | Exploited — local PoC passing |

---

## Executive summary

`Denial.withdraw` sends 1% of balance to an unauthenticated `partner` via a high-gas `call`, then pays the owner with `transfer`. An attacker sets themselves (or a burner contract) as partner and burns the forwarded gas so the owner payout cannot complete under a bounded gas budget.

---

## Challenge objectives

| # | Condition | How verified |
|---|-----------|--------------|
| 1 | Owner withdrawal fails under gas cap | `withdraw` call with ~1M gas reverts |

---

## Finding

### [M-01] Unbounded partner call + open `setWithdrawPartner`

| Field | Detail |
|-------|--------|
| **Severity** | Medium (DoS) |
| **Bug class** | Gas griefing / missing access control |
| **Location** | `setWithdrawPartner`, `withdraw` |

`partner.call{value: amountToSend}("")` forwards nearly all remaining gas. A malicious `receive` that loops forever consumes that budget; `owner.transfer` never gets enough gas, so the outer call fails when the verifier bounds gas.

#### Proof of concept

```bash
cd web3-ctf-challenges/21-ethernaut-denial
forge test --match-test testExploit -vv
```

---

## Exploit implementation

### SCH (`Exploit.s.sol`)

Deploy a helper whose `receive` infinite-loops, then `setWithdrawPartner` to it. Paste into the SCH editor (instance name: `denialInstance`).

### Local

Same logic in `test/DenialExploit.t.sol` / `script/Exploit.s.sol`.

---

## Fix (for real systems)

- Restrict `setWithdrawPartner` (e.g. `onlyOwner`).
- Cap gas on the partner call: `partner.call{value: amount, gas: 2300}("")` or pull-based payments.
- Prefer checks on success / accounting that do not couple owner payout to partner execution.
