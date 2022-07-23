// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {ERC20} from "solmate/tokens/ERC20.sol";

// Should it be erc721?
contract VotingTicket is ERC20 {
    mapping(address => mapping(address => uint256))
        public delegatedVotesPerUser;
    mapping(address => DelegatedVotes) public usersDelegations;
    mapping(address => uint256) numberofUserDelegatedVotes;

    address public owner;

    struct DelegatedVotes {
        uint256 amount;
        address delegate;
    }

    constructor() ERC20("VotingToken", "VTN", 18) {
        owner = msg.sender;
    }

    event VotesDelegated(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event VotesUndelegated(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    modifier userHasTokens(address addr) {
        require(balanceOf[addr] != 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == from);
        _burn(from, amount);
    }

    function numberOfVotes(address addr) public view returns (uint256) {
        require(usersDelegations[addr].amount <= balanceOf[addr]);
        return
            balanceOf[addr] -
            usersDelegations[addr].amount +
            numberofUserDelegatedVotes[addr];
    }

    // TODO: override transferFrom & transferTo to remove delegations of tokens users already doesnt have

    function delegateVotes(address to, uint256 amount)
        external
        userHasTokens(msg.sender)
        userHasTokens(to)
    {
        // prevent delegations to yourself
        require(msg.sender != to);

        if (usersDelegations[msg.sender].amount == 0) {
            // user doesn't have any votes delegated
            numberofUserDelegatedVotes[to] += amount;
            delegatedVotesPerUser[to][msg.sender] += amount;
            usersDelegations[msg.sender] = DelegatedVotes(amount, to);
            emit VotesDelegated(msg.sender, to, amount);
        } else if (usersDelegations[msg.sender].delegate == to) {
            // user wants to delegate more votes to same address

            // in case user tries to delegate more votes than he has
            require(
                delegatedVotesPerUser[to][msg.sender] + amount <=
                    balanceOf[msg.sender]
            );
            numberofUserDelegatedVotes[to] += amount;
            usersDelegations[msg.sender].amount += amount;
            delegatedVotesPerUser[to][msg.sender] += amount;
        } else {
            // user wants to delegate votes to another address
            removeDelegatedVotes(msg.sender, to);
            numberofUserDelegatedVotes[to] += amount;
            usersDelegations[msg.sender].amount += amount;
            usersDelegations[msg.sender].delegate = to;

            delegatedVotesPerUser[to][msg.sender] += amount;
        }
    }

    function removeDelegatedVotes(address initiator, address delegate)
        public
        userHasTokens(initiator)
        userHasTokens(delegate)
    {
        require(usersDelegations[initiator].delegate == delegate);

        uint256 amountOfDelegatedVotes = usersDelegations[initiator].amount;

        numberofUserDelegatedVotes[delegate] -= amountOfDelegatedVotes;
        usersDelegations[initiator].amount -= amountOfDelegatedVotes;
        usersDelegations[initiator].delegate = address(0);
        delegatedVotesPerUser[delegate][initiator] -= amountOfDelegatedVotes;

        emit VotesUndelegated(initiator, delegate, amountOfDelegatedVotes);
    }
}
