// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Merkle} from "murky/src/Merkle.sol";

contract Whitelist {

	Merkle m = new Merkle();   
    bytes32 public merkleRoot;
    
    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }

    function checkInWhitelist(bytes32[] calldata proof, uint64 maxAllowanceToMint) view public returns (bool) {
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxAllowanceToMint));     
		bool newVerified= m.verifyProof(merkleRoot,proof,leaf );
        return newVerified;
    }
    
}