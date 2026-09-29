// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Recovery, SimpleToken} from "../src/Recovery.sol";

/// Mimic OZ factory: setup calls generateToken so owner is the factory, not the player.
contract RecoveryFactoryStyleTest is Test {
    Recovery internal recoveryInstance;
    address internal player;

    function setUp() public {
        player = makeAddr("player");
        vm.deal(player, 1 ether);
        vm.deal(address(this), 0.001 ether);

        recoveryInstance = new Recovery();
        recoveryInstance.generateToken{value: 0.001 ether}("InitialToken", 100000);
    }

    function _token() internal view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(recoveryInstance), bytes1(0x01)))
                )
            )
        );
    }

    function testOwnerIsFactory() public view {
        assertEq(SimpleToken(_token()).owner(), address(this));
        assertEq(_token().balance, 0.001 ether);
    }

    function testPlayerDestroyReverts() public {
        vm.prank(player);
        vm.expectRevert(bytes("SimpleToken: owner only"));
        SimpleToken(_token()).destroy(payable(player));
    }

    function testFactoryDestroyWorks() public {
        SimpleToken(_token()).destroy(payable(player));
        assertEq(_token().balance, 0);
    }
}
