// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "lib/forge-std/src/Test.sol";
import {TokenSender, RandomToken} from "../src/MetaTokenSender.sol";
import {console} from "lib/forge-std/src/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MetaTokenTransfer is Test {
    using ECDSA for bytes32;

    //declare variables for holding instances of our contracts
    RandomToken public randomTokenContract;
    TokenSender public tokenSenderContract;

    // Get 3 addresses using their private keys
    uint8 privKeyOfUserAddress = 1;
    address userAddress = vm.addr(privKeyOfUserAddress);
    address relayerAddress = vm.addr(2);
    address recipientAddress = vm.addr(3);

    function setUp() public {
        // Deploy the contracts
        randomTokenContract = new RandomToken();
        tokenSenderContract = new TokenSender();

        // Mint 10,000 tokens to user address (for testing)
        vm.startPrank(userAddress);
        randomTokenContract.freeMint(10000 ether);

        // Have user infinite approve the token sender contract for transferring 'RandomToken'
        randomTokenContract.approve(
            address(tokenSenderContract),
            // This is uint256's max value (2^256 - 1) in hex
            // Fun Fact: There are 64 f's in here.
            // In hexadecimal, each digit can represent 4 bits
            // f is the largest digit in hexadecimal (1111 in binary)
            // 4 + 4 = 8 i.e. two hex digits = 1 byte
            // 64 digits = 32 bytes
            // 32 bytes = 256 bits = uint256
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        vm.stopPrank();
    }

    function test_nonceMetatransactions() public {
        uint nonce = 1;

        // Have user sign message to transfer 10 tokens to recipient
        bytes32 messageHash = tokenSenderContract.getHash(
            userAddress,
            10 ether,
            recipientAddress,
            address(randomTokenContract),
            nonce
        );
        bytes32 signedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );

        // Signs a digest digest with private key privateKey, returning (v,r,s)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privKeyOfUserAddress,
            signedMessageHash
        );
        // pack v, r, s into 65bytes
        bytes memory signature = abi.encodePacked(r, s, v);

        // Have the relayer execute the transaction on behalf of the user
        vm.prank(relayerAddress);
        tokenSenderContract.transfer(
            userAddress,
            10 ether,
            recipientAddress,
            address(randomTokenContract),
            nonce,
            signature
        );

        // Check the user's balance decreased, and recipient got 10 tokens
        uint userBalance = randomTokenContract.balanceOf(userAddress);
        uint recipientBalance = randomTokenContract.balanceOf(recipientAddress);

        assertEq(userBalance, 9990 ether);
        assertEq(recipientBalance, 10 ether);

        //increment the nonce
        nonce++;

        // Have user sign a second message, with a different nonce, to transfer 10 more tokens
        bytes32 messageHash2 = tokenSenderContract.getHash(
            userAddress,
            10 ether,
            recipientAddress,
            address(randomTokenContract),
            nonce
        );
        bytes32 signedMessageHash2 = MessageHashUtils.toEthSignedMessageHash(
            messageHash2
        );

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
            privKeyOfUserAddress,
            signedMessageHash2
        );
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        // Have the relayer execute the transaction on behalf of the user
        vm.prank(relayerAddress);
        tokenSenderContract.transfer(
            userAddress,
            10 ether,
            recipientAddress,
            address(randomTokenContract),
            nonce,
            signature2
        );

        userBalance = randomTokenContract.balanceOf(userAddress);
        recipientBalance = randomTokenContract.balanceOf(recipientAddress);

        assertEq(userBalance, 9980 ether);
        assertEq(recipientBalance, 20 ether);
    }

    function test_noReplay() public {
        uint nonce = 1;

        // Have user sign message to transfer 10 tokens to recipient
        bytes32 messageHash = tokenSenderContract.getHash(
            userAddress,
            10 ether,
            recipientAddress,
            address(randomTokenContract),
            nonce
        );
        bytes32 signedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privKeyOfUserAddress,
            signedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Have the relayer execute the transaction on behalf of the user
        vm.prank(relayerAddress);
        tokenSenderContract.transfer(
            userAddress,
            10 ether,
            recipientAddress,
            address(randomTokenContract),
            nonce,
            signature
        );

        // Have the relayer attempt to execute the same transaction again with the same signature
        // This time, we expect the transaction to be reverted because the signature has already been used.        vm.prank(relayerAddress);
        vm.expectRevert("Already executed!");
        tokenSenderContract.transfer(
            userAddress,
            10 ether,
            recipientAddress,
            address(randomTokenContract),
            nonce,
            signature
        );

    }
}