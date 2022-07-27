// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Poll.sol";
import "../src/VotingToken.sol";

uint256 constant votingPeriod = 9999999999;
uint8 constant quorumPercentage = 60;

contract ContractTest is Test {
    VotingToken internal Token;
    Poll internal PollContract;
    address public ownerAddr = address(0x1);
    address public userAddr = address(0x2);
    address public secondUserAddr = address(0x3);

    function setUp() public {
        vm.prank(ownerAddr);
        Token = new VotingToken();
        vm.prank(ownerAddr);
        PollContract = new Poll(votingPeriod, address(Token), quorumPercentage);

        mintVotesAsOwner(userAddr, 1000);
    }

    function testCreateProposal() public {
        vm.prank(userAddr);

        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        PollContract.createProposal(proposalName, options);

        (, , address creatorAddr, bool isActive) = PollContract.proposals(
            proposalName
        );
        assertEq(creatorAddr, userAddr);
        assertEq(isActive, true);
    }

    function testCreateProposalNameUnique() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
        vm.expectRevert("Proposal name should be unique");
        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
    }

    function testCreateProposalCorrectVotingOptions() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](1);
        options[0] = "opt1";

        vm.prank(userAddr);
        vm.expectRevert("Proposal should have at least two voting options");
        PollContract.createProposal(proposalName, options);
    }

    function testVotesForProposal() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        uint256 numberOfVotes = 5;

        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
        vm.prank(userAddr);
        PollContract.voteForProposal(proposalName, options[1], numberOfVotes);

        uint256 numberOfOptionVotes = PollContract.getProposalOptionVotes(
            proposalName,
            options[1]
        );
        assertEq(numberOfOptionVotes, numberOfVotes);
    }

    function testVotesForInactiveProposal() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        uint256 numberOfVotes = 900;

        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
        vm.prank(userAddr);
        PollContract.voteForProposal(proposalName, options[1], numberOfVotes);
        vm.prank(userAddr);
        vm.expectRevert("User can't interact with inactive proposal");
        PollContract.voteForProposal(proposalName, options[1], 60);
    }


    function testVotesForProposalAndQuorum() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        uint256 numberOfVotes = 900;

        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
        vm.prank(userAddr);
        PollContract.voteForProposal(proposalName, options[1], numberOfVotes);

        (, , , bool isActive) = PollContract.proposals(proposalName);
        assertEq(isActive, false);
    }

    function testVotesForProposalNotEnoughVotes() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        uint256 numberOfVotes = 9999;

        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
        vm.prank(userAddr);
        vm.expectRevert("User doesn't have enough votes");
        PollContract.voteForProposal(proposalName, options[1], numberOfVotes);
    }

    function testRemoveVotesFromProposal() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        uint256 numberOfVotes = 300;
        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
        vm.prank(userAddr);
        PollContract.voteForProposal(proposalName, options[0], numberOfVotes);
        vm.prank(userAddr);
        PollContract.removeVotesForProposal(proposalName, options[0]);

        uint256 numberOfOptionVotes = PollContract.getProposalOptionVotes(
            proposalName,
            options[0]
        );

        assertEq(numberOfOptionVotes, 0);
    }

    function testRemoveVotesFromProposalFailsNotVoted() public {
        string memory proposalName = "testProposal";
        string[] memory options = new string[](2);
        options[0] = "opt1";
        options[1] = "opt2";

        vm.prank(userAddr);
        PollContract.createProposal(proposalName, options);
        vm.prank(userAddr);
        vm.expectRevert("User hasn't yet voted for this proposal");
        PollContract.removeVotesForProposal(proposalName, options[0]);
    }

    function mintVotesAsOwner(address to, uint256 amount) private {
        vm.prank(ownerAddr);
        Token.mint(to, amount);
    }
}
