// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

// SCH harness reference (not compiled by local Foundry 0.8 profile).
interface AlienVm {
    function addr(uint256 privateKey) external returns (address);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

contract AlienScript {
    AlienVm internal constant vm = AlienVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint256 internal constant PLAYER_PRIVATE_KEY = 1;
    address internal constant PLAYER_ADDRESS = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
}
