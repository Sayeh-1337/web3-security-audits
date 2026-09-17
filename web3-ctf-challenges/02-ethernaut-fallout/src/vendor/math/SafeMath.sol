// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Minimal OpenZeppelin v3 SafeMath — only `add` is used by Fallout.sol.
 * Vendored so the 0.6 target compiles without a full OpenZeppelin checkout.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}
