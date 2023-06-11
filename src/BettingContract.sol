// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract BettingContract {
    using Address for address payable;
    
    AggregatorV3Interface internal dataFeed;

    enum Direction { Long, Short }

    struct Bet {
        address proposer;
        address acceptor;
        uint256 amount;
        uint256 expirationTime;
        uint256 closingTime;
        bool isActive;
        uint256 openingPrice;
        uint256 closingPrice;
        Direction direction;
    }

    mapping(uint256 => Bet) public bets;
    uint256 public totalBets;
    address public tokenAddress;
    address public owner;

    event BetProposed(uint256 indexed betId, address indexed proposer, uint256 betAmount);
    event BetAccepted(uint256 indexed betId, address indexed acceptor, uint256 betAmount);
    event BetSettled(uint256 indexed betId, address indexed winner, uint256 winnings);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
        dataFeed = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        );
    }
    
    // This function allows a user to propose a new bet with given parameters. 
    // It then creates a new bet by storing its properties in the `bets` mapping
    // with the total number of bets seen so far as the key.
    function proposeBet(
        uint256 _expirationTime,
        uint256 _closingTime,
        uint256 _amount,
        Direction _direction
    ) external {
        require(_expirationTime > block.timestamp, "Expiration time must be in the future");
        require(_closingTime > _expirationTime, "Closing time must be after expiration time");
        require(_amount > 0, "Bet amount must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);

        bets[totalBets] = Bet({
            proposer: msg.sender,
            acceptor: address(0),
            amount: _amount,
            expirationTime: _expirationTime,
            closingTime: _closingTime,
            isActive: false,
            openingPrice: 0,
            closingPrice: 0,
            direction: _direction
        });

        emit BetProposed(totalBets, msg.sender, _amount);
        totalBets++;
    }

    // This function allows a user to accept a proposed bet as the acceptor.
    // If all checks pass, it transfers the required amount of tokens from the
    // sender's wallet to this contract, updates the bet properties, and marks
    // the bet as active.
    function acceptBet(uint256 _betId) external {
        require(_betId < totalBets, "Invalid bet ID");
        Bet storage bet = bets[_betId];
        require(!bet.isActive, "Bet is already active");
        require(bet.acceptor != msg.sender, "User A cannot join their own bet");

        IERC20 token = IERC20(tokenAddress);
        uint256 betAmount = bet.amount;
        token.transferFrom(msg.sender, address(this), betAmount);

        bet.acceptor = msg.sender;
        bet.isActive = true;

        emit BetAccepted(_betId, msg.sender, betAmount);
    }

    // This function is used to settle the bet with the given `_betId`.
    // It then requests the latest data from an external oracle service to get the
    // latest market price update. The `closingPrice` of the corresponding bet is
    // updated with this value and the `isActive` flag for the bet is set to false.

    // Depending on the direction of the bet, it checks if the opening price is 
    // less than closing price. If so, it sets the `winner` as the proposer else 
    // it is set as the acceptor.

    // The amount credited to the winner's wallet and the fee taken by the settler 
    // are set to 2% of the `winnings`
    function settleBet(uint256 _betId) external {
        require(_betId < totalBets, "Invalid bet ID");
        Bet storage bet = bets[_betId];
        require(bet.isActive, "Bet is not active");
        require(block.timestamp >= bet.closingTime, "Closing time not reached");

        (,int answer,,,) = dataFeed.latestRoundData();

        bet.closingPrice = uint256(answer);
        bet.isActive = false;

        address payable winner;
        if (bet.openingPrice < uint256(answer) && bet.direction == Direction.Long) {
            winner = payable(bet.proposer);
        } else {
            winner = payable(bet.acceptor);
        }

        IERC20 token = IERC20(tokenAddress);
        uint256 fee = bet.amount * 2 * 2 / 100; // 2% fee
        uint256 winnings = bet.amount * 2 - fee;
        token.transfer(winner, winnings);
        token.transfer(msg.sender, fee);

        emit BetSettled(_betId, winner, winnings);
    }
}
