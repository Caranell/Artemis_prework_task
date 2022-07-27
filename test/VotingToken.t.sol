// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/VotingToken.sol";

contract ContractTest is Test {
    VotingToken internal Token;
    address public ownerAddr = address(0x1);
    address public userAddr = address(0x2);
    address public delegateAddr = address(0x3);
    address public secondDelegateAddr = address(0x4);

    function setUp() public {
        vm.prank(ownerAddr);
        Token = new VotingToken();
    }

    function testMintIfNotAnOwner() public {
        vm.expectRevert("User should be owner to preform this operation");
        vm.prank(address(0));
        Token.mint(msg.sender, 1000);
    }

    function testMintAsOwner() public {
        vm.prank(ownerAddr);

        uint16 numberOfTokensToMint = 1000;
        Token.mint(msg.sender, numberOfTokensToMint);

        assertEq(numberOfTokensToMint, Token.balanceOf(msg.sender));
    }

    function testBurnFails() public {
        vm.prank(address(0));
        vm.expectRevert("User can only burn own tokens");
        Token.burn(ownerAddr, 1000);
    }

    function testVotesDelegationFirstTime() public {
        mintVotesAsOwner(userAddr, 5);
        mintVotesAsOwner(delegateAddr, 5);

        uint16 votesToDelegate = 4;

        vm.prank(userAddr);
        Token.delegateVotes(delegateAddr, votesToDelegate);

        (uint256 amount, address delegate) = Token.usersDelegations(userAddr);

        assertEq(
            Token.numberOfUserDelegatedVotes(delegateAddr),
            votesToDelegate
        );
        assertEq(
            Token.delegatedVotesPerUser(delegateAddr, userAddr),
            votesToDelegate
        );
        assertEq(amount, votesToDelegate);
        assertEq(delegate, delegateAddr);
    }

    function testVotesDelegationToSameDelegate() public {
        mintVotesAsOwner(userAddr, 5);
        mintVotesAsOwner(delegateAddr, 5);
        mintVotesAsOwner(secondDelegateAddr, 5);

        uint16 votesToDelegate = 4;
        uint16 newVotesToDelegate = 1;

        vm.prank(userAddr);
        Token.delegateVotes(delegateAddr, votesToDelegate);
        vm.prank(userAddr);
        Token.delegateVotes(secondDelegateAddr, newVotesToDelegate);

        (uint256 amount, address delegate) = Token.usersDelegations(userAddr);

        assertEq(Token.numberOfUserDelegatedVotes(delegateAddr), 0);
        assertEq(
            Token.numberOfUserDelegatedVotes(secondDelegateAddr),
            newVotesToDelegate
        );
        assertEq(Token.delegatedVotesPerUser(delegateAddr, userAddr), 0);
        assertEq(
            Token.delegatedVotesPerUser(secondDelegateAddr, userAddr),
            newVotesToDelegate
        );
        assertEq(amount, newVotesToDelegate);
        assertEq(delegate, secondDelegateAddr);
    }

    function testVotesDelegationToNewDelegate() public {
        mintVotesAsOwner(userAddr, 5);
        mintVotesAsOwner(delegateAddr, 5);

        uint16 votesToDelegate = 4;
        uint16 newVotesToDelegate = 1;

        vm.prank(userAddr);
        Token.delegateVotes(delegateAddr, votesToDelegate);
        vm.prank(userAddr);
        Token.delegateVotes(delegateAddr, newVotesToDelegate);

        (uint256 amount, address delegate) = Token.usersDelegations(userAddr);

        assertEq(
            Token.numberOfUserDelegatedVotes(delegateAddr),
            votesToDelegate + newVotesToDelegate
        );
        assertEq(
            Token.delegatedVotesPerUser(delegateAddr, userAddr),
            votesToDelegate + newVotesToDelegate
        );
        assertEq(amount, votesToDelegate + newVotesToDelegate);
        assertEq(delegate, delegateAddr);
    }

    function testVotesDelegationToYourselfFails() public {
        mintVotesAsOwner(userAddr, 5);

        uint16 votesToDelegate = 4;

        vm.expectRevert("Delegation votes to yourself is prohibited");
        vm.prank(userAddr);
        Token.delegateVotes(userAddr, votesToDelegate);
    }

    function testVotesDelegationUnsufficientBalanceFails() public {
        mintVotesAsOwner(userAddr, 5);
        mintVotesAsOwner(delegateAddr, 5);

        uint16 votesToDelegate = 6;

        vm.prank(userAddr);
        vm.expectRevert("User doesn't have enough tokens to delegate");
        Token.delegateVotes(delegateAddr, votesToDelegate);
    }

    function testRemoveDelegatedVotesFails() public {
        mintVotesAsOwner(userAddr, 5);

        vm.prank(userAddr);
        vm.expectRevert("User hasn't yet delegated any votes");
        Token.removeDelegatedVotes();
    }

    function testRemoveDelegatedVotes() public {
        mintVotesAsOwner(userAddr, 5);
        mintVotesAsOwner(delegateAddr, 5);

        uint16 votesToDelegate = 4;

        vm.prank(userAddr);
        Token.delegateVotes(delegateAddr, votesToDelegate);
        vm.prank(userAddr);
        Token.removeDelegatedVotes();

        (uint256 amount, address delegate) = Token.usersDelegations(userAddr);

        assertEq(Token.numberOfUserDelegatedVotes(delegateAddr), 0);
        assertEq(Token.delegatedVotesPerUser(delegateAddr, userAddr), 0);
        assertEq(amount, 0);
        assertEq(delegate, address(0));
    }

    function mintVotesAsOwner(address to, uint256 amount) private {
        vm.prank(ownerAddr);
        Token.mint(to, amount);
    }
}
