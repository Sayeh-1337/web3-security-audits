# Denial — Audit Notes

## Surface

| Entry | Auth | Effect |
|-------|------|--------|
| `setWithdrawPartner(address)` | **none** | Sets `partner` used by `withdraw` |
| `withdraw()` | anyone | Pays partner 1%, then owner 1% of balance |
| `receive()` | — | Accepts ETH |

## Storage / layout

- `partner` — withdraw “partner” callback address
- `owner` — receives `transfer` after partner call
- `timeLastWithdrawn` / `withdrawPartnerBalances` — bookkeeping (not needed for exploit)

## Bug sketch

1. Unauthenticated `setWithdrawPartner` → attacker installs grief contract.
2. `partner.call` forwards nearly all gas; return value ignored.
3. Grief `receive` infinite-loops / burns gas → remaining gas < what `owner.transfer` needs → withdraw reverts under bounded gas (SCH check).

## Exploit outline

1. Deploy `HelperContract` with `receive() { while (true) {} }`.
2. `denialInstance.setWithdrawPartner(address(helper))`.
3. Verifier calls `withdraw` with limited gas → fails.
