// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

//  Implement some form of voting ballot**

// Implement a pair of contracts: one that serves as a voting ballot and another as a token. 
// This voting ballot allows holders of the token to create proposals and to vote on said proposals. 
// The voting period duration must be identical for all proposals and should be defined on the voting ballot contract. 
// Proposals created on the voting ballot must include a predefined list of voting options. 
// Any token holder can vote on any ongoing proposal or delegate their voting power to another holder. 
// A proposal is only passed if a quorum, predefined in the voting ballot itself, is reached.

contract Ballot {
    address immutable tokenAddr;
    uint256 immutable votingPeriod;
    address immutable owner;
    uint8 immutable quroumRequiredPercentage;

    // reworked events (quorumReached + finished -> quorumReached+ProposalFinished+ProposalTImedOut)
    event ProposalQuorumReached(string indexed proposalName, string winningOption);
    event ProposalTimedOut(string indexed proposalName);
    event ProposalFinished(string indexed proposalName);
    event ProposalCreated(string indexed proposalName, address indexed creator);
    event VotesAdded(string indexed proposalName, string option, uint numberOfVotes);

    mapping(string => Proposal) public proposals;

    struct Proposal {
        // ??? should we have name or mapping would suffice
        uint256 creationTime;
        string[] votingOptions;
        // prevent computing 'creation+voting period' every time
        uint256 deadlineTime;
        address creatorAddr;
        bool isActive;

        // TODO: add votes mapping
        // mapping(string => int64) optionVotes;
        // mapping(string => mapping(address=> int64)) optionVotesByAddress;
    }

    constructor(
        uint256 _votingPeriod,
        address _tokenAddr,
        uint8 _quroumRequiredPercentage
    ) {
        owner = msg.sender;

        votingPeriod = _votingPeriod;
        quroumRequiredPercentage = _quroumRequiredPercentage;
        tokenAddr = _tokenAddr;
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
        require(VotingTicket(tokenAddr).balanceOf(msg.sender) != 0);
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

        Proposal memory proposal = Proposal(
            block.timestamp,
            _votingOptions,
            block.timestamp + votingPeriod,
            msg.sender,
            true
        );
        proposals[_name] = proposal;

        emit ProposalCreated(_name, msg.sender);
    }

    //  string memory option,
    //   int16 votes
    function voteForProposal(string memory _name)
        public
        userHasTokens
        isPropsalActive(_name)
        isProposalTimeFinished(_name)
    {
        require(proposals[_name].isActive);

        // int256 numberOfVotesAvailable = Ticket(tokenAddr).balanceOf(msg.sender);
        // require(numberOfVotesAvailable>=votes);
        // proposals[proposal].votes += numberOfVotesAvailable;

        checkIsQuorumReached(_name);
    }

    function checkIsQuorumReached(string memory _name) private {
        // if ticket.totalSupply * quorumPercent >= option.votes
        emit ProposalQuorumReached(_name);
        makeProposalInactive(_name);
    }

    function makeProposalInactive(string memory _name) private {
        proposals[_name].isActive = false;
        emit ProposalFinished(_name);
    }
}
