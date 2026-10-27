# Shop — Audit Notes

## Surface

| Entry | Auth | Effect |
|-------|------|--------|
| `buy()` | anyone (as `Buyer`) | If `buyer.price() >= price && !isSold`, sets `isSold` then `price = buyer.price()` |

## Storage

- `price` — starts at 100; overwritten by second `buyer.price()` call
- `isSold` — flipped true before the second `price()` read

## Bug sketch

1. View callback `Buyer.price()` is not a fixed value — attacker controls both returns.
2. Between the two calls, `isSold` becomes `true`, so the buyer can branch on it.
3. Return 100 (pass gate) then 0 (set final price).

## Exploit outline

1. Deploy helper implementing `price()` → `isSold() ? 0 : 100`.
2. Call `shop.buy()` from the helper.
