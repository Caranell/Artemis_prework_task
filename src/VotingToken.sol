// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract VotingToken is ERC20 {
    mapping(address => mapping(address => uint256))
        public delegatedVotesPerUser;
    mapping(address => DelegatedVotes) public usersDelegations;
    mapping(address => uint256) public numberOfUserDelegatedVotes;

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
        require(
            balanceOf[addr] != 0,
            "User should have tokens to preform this operation"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "User should be owner to preform this operation"
        );
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == from, "User can only burn own tokens");

        _burn(from, amount);
        _removeDelegatedVotes(from);
    }

    function numberOfVotesAvailable(address addr)
        external
        view
        returns (uint256)
    {
        require(
            usersDelegations[addr].amount <= balanceOf[addr],
            "User has delegated all his tokens"
        );
        return
            balanceOf[addr] -
            usersDelegations[addr].amount +
            numberOfUserDelegatedVotes[addr];
    }

    function delegateVotes(address to, uint256 amount)
        external
        userHasTokens(msg.sender)
        userHasTokens(to)
        returns (bool)
    {
        require(msg.sender != to, "Delegation votes to yourself is prohibited");
        require(
            delegatedVotesPerUser[to][msg.sender] + amount <=
                balanceOf[msg.sender],
            "User doesn't have enough tokens to delegate"
        );

        // user doesn't have any votes delegated
        if (getUserDelegate(msg.sender) == address(0)) {
            numberOfUserDelegatedVotes[to] += amount;
            delegatedVotesPerUser[to][msg.sender] += amount;
            usersDelegations[msg.sender] = DelegatedVotes(amount, to);
            return true;
        }

        // user wants to delegate more votes to same address
        if (usersDelegations[msg.sender].delegate == to) {
            numberOfUserDelegatedVotes[to] += amount;
            usersDelegations[msg.sender].amount += amount;
            delegatedVotesPerUser[to][msg.sender] += amount;

            return true;
        }

        // user wants to delegate votes to another address
        _removeDelegatedVotes(msg.sender);
        numberOfUserDelegatedVotes[to] += amount;
        delegatedVotesPerUser[to][msg.sender] += amount;
        usersDelegations[msg.sender].amount += amount;
        usersDelegations[msg.sender].delegate = to;

        emit VotesDelegated(msg.sender, to, amount);

        return true;
    }

    function removeDelegatedVotes()
        external
        userHasTokens(msg.sender)
    {
        address delegate = getUserDelegate(msg.sender);
        require(delegate != address(0), "User hasn't yet delegated any votes");

        uint256 amountOfDelegatedVotes = usersDelegations[msg.sender].amount;

        numberOfUserDelegatedVotes[delegate] -= amountOfDelegatedVotes;
        usersDelegations[msg.sender].amount -= amountOfDelegatedVotes;
        usersDelegations[msg.sender].delegate = address(0);
        delegatedVotesPerUser[delegate][msg.sender] -= amountOfDelegatedVotes;

        emit VotesUndelegated(msg.sender, delegate, amountOfDelegatedVotes);
    }

    function _removeDelegatedVotes(address initiator)
        private
        userHasTokens(initiator)
    {
        address delegate = getUserDelegate(initiator);
        require(delegate != address(0), "User hasn't yet delegated any votes");

        uint256 amountOfDelegatedVotes = usersDelegations[initiator].amount;

        numberOfUserDelegatedVotes[delegate] -= amountOfDelegatedVotes;
        usersDelegations[initiator].amount -= amountOfDelegatedVotes;
        usersDelegations[initiator].delegate = address(0);
        delegatedVotesPerUser[delegate][initiator] -= amountOfDelegatedVotes;

        emit VotesUndelegated(initiator, delegate, amountOfDelegatedVotes);
    } 

    function getUserDelegate(address addr) private view returns (address) {
        address delegate = usersDelegations[addr].delegate;

        if (delegate != address(0)) {
            return delegate;
        }

        return address(0);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        _removeDelegatedVotes(msg.sender);

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        _removeDelegatedVotes(from);

        emit Transfer(from, to, amount);

        return true;
    }
}
