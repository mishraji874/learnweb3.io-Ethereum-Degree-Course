// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {Login} from "../src/Login.sol";


contract AccessPrivateData is Test {
    //declare a variable for holding an instance of our Login contract
    Login public login;

    // To save space, we're using bytes32 arrays
    bytes32 usernameBytes = "test";
    bytes32 passwordBytes = "password";

    function setUp() public {
        // Deploy the Login Contract
        login = new Login(usernameBytes, passwordBytes);
    }

    function test_attack() public view {
        // Get the storage slot 0 as string
        bytes32 slot0Bytes = (vm.load(address(login), bytes32(uint256(0))));

        // Get the storage slot 1 as string
        bytes32 slot1Bytes = (vm.load(address(login), bytes32(uint256(1))));

        assertEq(slot0Bytes, usernameBytes);
        assertEq(slot1Bytes, passwordBytes);
    }
}
