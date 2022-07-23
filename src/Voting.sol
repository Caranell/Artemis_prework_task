// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./VotingToken.sol";

//  Implement some form of voting ballot**

// Implement a pair of contracts: one that serves as a voting ballot and another as a token.
// This voting ballot allows holders of the token to create proposals and to vote on said proposals.
// The voting period duration must be identical for all proposals and should be defined on the voting ballot contract.
// Proposals created on the voting ballot must include a predefined list of voting options.
// Any token holder can vote on any ongoing proposal or delegate their voting power to another holder.
// A proposal is only passed if a quorum, predefined in the voting ballot itself, is reached.

// FIXME: check all uints and ints

// To think about : if 80% votes for anotherOption, we can disable current proposal

contract Ballot {
    address immutable ticketTokenAddr;
    uint256 immutable votingPeriod;
    address immutable owner;
    uint8 immutable quroumRequiredPercentage;

    // reworked events (quorumReached + finished -> quorumReached+ProposalFinished+ProposalTImedOut)
    event ProposalQuorumReached(
        string indexed proposalName,
        string winningOption
    );
    event ProposalTimedOut(string indexed proposalName);
    event ProposalFinished(string indexed proposalName);
    event ProposalCreated(string indexed proposalName, address indexed creator);
    event VotesAdded(
        string indexed proposalName,
        string option,
        uint256 numberOfVotes
    );

    mapping(string => Proposal) public proposals;

    struct Proposal {
        // ??? should we have name or mapping would suffice
        uint256 creationTime;
        // prevent computing 'creation+voting period' every time
        uint256 deadlineTime;
        string[] votingOptions;
        address creatorAddr;
        bool isActive;
        mapping(string => uint256) optionVotes;
        mapping(string => mapping(address => uint256)) optionVotesByAddress;
    }

    constructor(
        uint256 _votingPeriod,
        address _ticketTokenAddr,
        uint8 _quroumRequiredPercentage
    ) {
        owner = msg.sender;

        votingPeriod = _votingPeriod;
        quroumRequiredPercentage = _quroumRequiredPercentage;
        ticketTokenAddr = _ticketTokenAddr;
    }

    modifier isPropsalActive(string memory proposalName) {
        require(proposals[proposalName].isActive);
        _;
    }

    modifier isProposalTimeFinished(string memory _name) {
        uint256 deadline = proposals[_name].deadlineTime;
        if (deadline >= block.timestamp) {
            _;
        }
        makeProposalInactive(_name);
    }

    modifier userHasTokens() {
        require(VotingTicket(ticketTokenAddr).balanceOf(msg.sender) != 0);
        // TODO: depends on the implementation, maybe we should also check number of delegated votes
        _;
    }

    function createProposal(string memory _name, string[] memory _votingOptions)
        public
        userHasTokens
    {
        // name should be unique
        require(proposals[_name].creationTime != 0);

        // checking that there're at least 2 options or more
        require(_votingOptions.length > 1);
        // TODO: what should we do with proposals with identical names? maybe hash them
        // what if same creator adds same proposal

        Proposal storage newProposal = proposals[_name];
        newProposal.creationTime = block.timestamp;
        newProposal.votingOptions = _votingOptions;
        newProposal.deadlineTime = block.timestamp + votingPeriod;
        newProposal.creatorAddr = msg.sender;
        newProposal.isActive = true;

        emit ProposalCreated(_name, msg.sender);
    }

    function voteForProposal(
        string memory _name,
        string memory _option,
        uint16 _votes
    )
        public
        userHasTokens
        isPropsalActive(_name)
        isProposalTimeFinished(_name)
    {
        require(proposals[_name].isActive);

        uint256 numberOfVotesAvailable = VotingTicket(ticketTokenAddr)
            .numberOfVotes(msg.sender);
        require(numberOfVotesAvailable >= _votes);
        proposals[_name].optionVotes[_option] += numberOfVotesAvailable;
        proposals[_name].optionVotesByAddress[_option][msg.sender] += _votes;

        checkIsQuorumReached(_name, _option);
    }

    function checkIsQuorumReached(
        string memory _proposalName,
        string memory _option
    ) private {
        uint256 numberOfVotes = proposals[_proposalName].optionVotes[_option];
        uint256 totalSupply = VotingTicket(ticketTokenAddr).totalSupply();
        if ((numberOfVotes / totalSupply) * 100 >= quroumRequiredPercentage) {
            emit ProposalQuorumReached(_proposalName, _option);
            makeProposalInactive(_proposalName);
        }
    }

    function makeProposalInactive(string memory _name) private {
        proposals[_name].isActive = false;
        emit ProposalFinished(_name);
    }
}
