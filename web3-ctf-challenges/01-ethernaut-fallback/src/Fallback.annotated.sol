// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// AUDIT: Annotated copy for review only. Deploy / test against src/Fallback.sol (unmodified CTF target).
// See AUDIT-NOTES.md and WRITEUP.md for full findings.

contract Fallback {
    // AUDIT [INFO]: Public mapping — anyone can read all contribution totals.
    mapping(address => uint256) public contributions;

    // AUDIT [INFO]: Single privileged role. All ownership bugs escalate to fund theft via withdraw().
    address public owner;

    constructor() {
        owner = msg.sender;

        // AUDIT [INFO / I-01]: Deployer credited 1000 ether without paying.
        // Misleading: suggests contribute() race is the real path. It is not (see receive()).
        contributions[msg.sender] = 1000 * (1 ether);
    }

    // AUDIT [OK]: Standard modifier — correctly used on withdraw() only.
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        // AUDIT [INFO]: Caps each deposit below 0.001 ether.
        require(msg.value < 0.001 ether);

        contributions[msg.sender] += msg.value;

        // AUDIT [INFO]: Strict ownership rule — must beat owner's total contribution.
        // AUDIT [CRITICAL / C-01]: NOT the only code path that sets owner. receive() bypasses this check.
        // AUDIT [INFO / I-02]: No OwnershipTransferred event emitted here.
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    // AUDIT [OK]: View-only. No security impact.
    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        // AUDIT [CRITICAL downstream]: Drains entire balance — catastrophic once C-01 is exploited.
        // AUDIT [MEDIUM / M-01]: .transfer() only forwards 2300 gas; may fail for smart-wallet owners.
        // AUDIT [INFO / I-03]: No reentrancy guard (acceptable in this minimal contract; risky if extended).
        // AUDIT [INFO / I-02]: No Withdrawn(amount, to) event.
        payable(owner).transfer(address(this).balance);
    }

    // AUDIT [CRITICAL / C-01]: PRIMARY VULNERABILITY
    // - Triggered by plain ETH transfer (call{value:}("")), NOT by contribute().
    // - Requires only contributions[msg.sender] > 0 (any dust amount).
    // - Does NOT require contributions[msg.sender] > contributions[owner].
    // - Exploit: contribute{value: 1 wei}() then call{value: 1 wei}("") then withdraw().
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
