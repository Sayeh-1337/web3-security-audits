// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Solver {
    function whatIsTheMeaningOfLife() external view returns (uint256);
}

/// @notice Adapted from OpenZeppelin Ethernaut level 18.
contract MagicNumber {
    Solver public solver;

    function setSolver(address solverAddress) external {
        solver = Solver(solverAddress);
    }

    function whatIsTheMeaningOfLife() external view returns (uint256) {
        return solver.whatIsTheMeaningOfLife();
    }
}
