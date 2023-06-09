// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BettingContract {
    using Address for address payable;

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

    event BetOpened(uint256 indexed betId, address indexed userA, uint256 betAmount);
    event BetJoined(uint256 indexed betId, address indexed userB, uint256 betAmount);
    event BetClosed(uint256 indexed betId, address indexed winner, uint256 winnings);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    function openBet(
        uint256 _expirationTime,
        uint256 _closingTime,
        uint256 _betAmount,
        Direction _direction
    ) external {
        require(_expirationTime > block.timestamp, "Expiration time must be in the future");
        require(_closingTime > _expirationTime, "Closing time must be after expiration time");
        require(_betAmount > 0, "Bet amount must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _betAmount);

        bets[totalBets] = Bet({
            betProposer: msg.sender,
            betAcceptor: address(0),
            betAmount: _betAmount,
            expirationTime: _expirationTime,
            closingTime: _closingTime,
            isActive: false,
            openingPrice: 0,
            closingPrice: 0,
            direction: _direction
        });

        emit BetOpened(totalBets, msg.sender, _betAmount);
        totalBets++;
    }

    function joinBet(uint256 _betId) external {
        require(_betId < totalBets, "Invalid bet ID");
        Bet storage bet = bets[_betId];
        require(!bet.isActive, "Bet is already active");
        require(bet.proposer == address(0), "Bet already accepted");
        require(bet.acceptor != msg.sender, "User A cannot join their own bet");

        IERC20 token = IERC20(tokenAddress);
        uint256 betAmount = bet.amount;
        token.transferFrom(msg.sender, address(this), betAmount);

        bet.acceptor = msg.sender;
        bet.isActive = true;

        emit BetJoined(_betId, msg.sender, betAmount);
    }

    function closeBet(uint256 _betId, uint256 _closingPrice) external {
        require(_betId < totalBets, "Invalid bet ID");
        Bet storage bet = bets[_betId];
        require(bet.isActive, "Bet is not active");
        require(block.timestamp >= bet.closingTime, "Closing time not reached");

        bet.isActive = false;
        bet.closingPrice = _closingPrice;

        address payable winner;
        if (bet.openingPrice < bet.closingPrice) {
            winner = payable(bet.proposer);
        } else {
            winner = payable(bet.acceptor);
        }

        IERC20 token = IERC20(tokenAddress);
        uint256 winnings = bet.amount * 2;
        token.transfer(winner, winnings);

        emit BetClosed(_betId, winner, winnings);
    }
}
