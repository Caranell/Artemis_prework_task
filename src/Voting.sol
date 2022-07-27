// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./VotingToken.sol";

// FIXME: check all uints and ints

contract Ballot {
    address immutable votingTokenAddr;
    uint256 immutable votingPeriod;
    address immutable owner;
    uint8 immutable quroumRequiredPercentage;

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
        address _votingTokenAddr,
        uint8 _quroumRequiredPercentage
    ) {
        owner = msg.sender;

        votingPeriod = _votingPeriod;
        quroumRequiredPercentage = _quroumRequiredPercentage;
        votingTokenAddr = _votingTokenAddr;
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
        require(VotingToken(votingTokenAddr).balanceOf(msg.sender) != 0);
        _;
    }

    function createProposal(string calldata _name, string[] calldata _votingOptions)
        external
        userHasTokens
    {
        // name should be unique
        require(proposals[_name].creationTime != 0);

        // checking that there're at least 2 options or more
        require(_votingOptions.length > 1);

        Proposal storage newProposal = proposals[_name];
        newProposal.creationTime = block.timestamp;
        newProposal.votingOptions = _votingOptions;
        newProposal.deadlineTime = block.timestamp + votingPeriod;
        newProposal.creatorAddr = msg.sender;
        newProposal.isActive = true;

        emit ProposalCreated(_name, msg.sender);
    }

    function voteForProposal(
        string calldata _name,
        string calldata _option,
        uint16 _votes
    )
        external
        userHasTokens
        isPropsalActive(_name)
        isProposalTimeFinished(_name)
    {
        uint256 numberOfVotesAvailable = VotingToken(votingTokenAddr)
            .numberOfVotesAvailable(msg.sender);
        require(numberOfVotesAvailable >= _votes);

        proposals[_name].optionVotes[_option] += numberOfVotesAvailable;
        proposals[_name].optionVotesByAddress[_option][msg.sender] += _votes;

        checkIsQuorumReached(_name, _option);
    }

    function removeVotesForProposal(string calldata _name, string calldata _option)
        external
        userHasTokens
        isPropsalActive(_name)
        isProposalTimeFinished(_name)
    {
        uint256 numberOfUserVotes = proposals[_name].optionVotesByAddress[
            _option
        ][msg.sender];

        require(numberOfUserVotes != 0);

        proposals[_name].optionVotes[_option] -= numberOfUserVotes;
        proposals[_name].optionVotesByAddress[_option][
            msg.sender
        ] -= numberOfUserVotes;
    }

    function checkIsQuorumReached(
        string memory _proposalName,
        string memory _option
    ) private {
        uint256 numberOfVotes = proposals[_proposalName].optionVotes[_option];
        uint256 totalSupply = VotingToken(votingTokenAddr).totalSupply();

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
