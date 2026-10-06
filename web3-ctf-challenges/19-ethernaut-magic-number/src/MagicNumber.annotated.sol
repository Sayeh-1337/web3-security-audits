// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/MagicNumber.sol.
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

interface Solver {
    function whatIsTheMeaningOfLife() external view returns (uint256);
}

contract MagicNumber {
    // AUDIT [INFO]: solver is unconstrained — any address can be set, including raw bytecode contracts.
    Solver public solver;

    // AUDIT [INFO]: No access control / size check here. Level verifier checks solver code size ≤ 10.
    function setSolver(address solverAddress) external {
        solver = Solver(solverAddress);
    }

    // AUDIT [INFO]: Forwards to solver; return value must be 42 for the level to pass.
    function whatIsTheMeaningOfLife() external view returns (uint256) {
        return solver.whatIsTheMeaningOfLife();
    }
}
