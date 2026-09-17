// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/CoinFlip.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract CoinFlip {
    // AUDIT [INFO]: Win condition — reach 10. Public so anyone can read progress.
    uint256 public consecutiveWins;

    // AUDIT [INFO]: Blocks same-block double flips. Does NOT make the outcome unpredictable.
    uint256 lastHash;

    // AUDIT [INFO]: Exactly 2^255. Dividing a uint256 by this yields the MSB (0 or 1).
    // AUDIT [INFO / I-01]: Not `constant`/`immutable` — wastes gas; not a security issue.
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY — predictable "randomness"
    // - Outcome is derived from blockhash(block.number - 1), which is public on-chain
    //   and known to every transaction in the current block.
    // - An attacker contract (or script) can recompute the exact same side and always guess right.
    // - Must call once per block because lastHash rejects a second flip with the same blockValue.
    // - Exploit: side = uint256(blockhash(block.number - 1)) / FACTOR == 1; flip(side); × 10 blocks.
    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        // AUDIT [OK]: Prevents farming multiple wins in one block. Forces 10 separate blocks.
        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;

        // AUDIT [CRITICAL]: This is deterministic, not random. Same inputs → same side for all callers.
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            // AUDIT [INFO]: Wrong guess resets the streak — attacker never guesses wrong if they copy the PRNG.
            consecutiveWins = 0;
            return false;
        }
    }
}
