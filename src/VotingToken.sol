// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// is ERC721
contract VotingTicket {
    //     // _mint
    mapping(address => uint256) public delegatedVotes;
    mapping(address => uint256) public balanceOf;

    // maybe should add amount delegated
    function delegateVolte(address to) public {}

    //     function removeDelegate() public {

    //     }
}
