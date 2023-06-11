// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/BettingContract.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BettingContractTest is Test {
    BettingContract betting;
    address tokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // usdc
    uint256 betAmount = 1000000000;
    uint256 testExpirationTime = block.timestamp + 10 minutes;
    uint256 testClosingTime = block.timestamp + 20 minutes;
    address public proposerAdr = address(1);
    address public acceptorAdr = address(2);
    address public settlerAdr = address(3);
    IERC20 token = IERC20(tokenAddress);

    BettingContract bettingContract;

    event BetOpened(
        uint256 indexed betId,
        address indexed userA,
        uint256 betAmount
    );
    event BetJoined(
        uint256 indexed betId,
        address indexed userB,
        uint256 betAmount
    );
    event BetClosed(
        uint256 indexed betId,
        address indexed winner,
        uint256 winnings
    );

    function setUp() public {
        betting = new BettingContract(tokenAddress);
    }

    function testOpenBet() public {
        vm.deal(proposerAdr, 1 ether);
        deal(tokenAddress, proposerAdr, betAmount);
        vm.prank(proposerAdr);
        token.approve(address(betting), betAmount);
        vm.prank(proposerAdr);
        betting.proposeBet(
            testExpirationTime,
            testClosingTime,
            betAmount,
            BettingContract.Direction.Long
        );
        assertEq(token.balanceOf(address(betting)), betAmount);
        assertEq(betting.totalBets(), 1);
    }

    function testAcceptsBet() public {
        // Set up test parameters
        uint256 expirationTime = block.timestamp + 3600; // 1 hour from now
        uint256 closingTime = expirationTime + 3600; // 2 hours from now
        uint256 expectedTotalBetAmount = 2 * betAmount;
        BettingContract.Direction direction = BettingContract.Direction.Long;

        vm.deal(acceptorAdr, 1 ether);
        deal(tokenAddress, acceptorAdr, betAmount);
        vm.prank(proposerAdr);
        token.approve(address(betting), betAmount);
        vm.prank(acceptorAdr);
        token.approve(address(betting), betAmount);

        vm.prank(proposerAdr);
        betting.proposeBet(expirationTime, closingTime, betAmount, direction);

        vm.prank(acceptorAdr);
        betting.acceptBet(0);

        // Verify that the bet state has been updated correctly
        (
            ,
            address acceptor,
            uint256 amount_0,
            uint256 expirationTime_0,
            uint256 closingTime_0,
            bool isActive_0,
            uint256 openingPrice_0,
            uint256 closingPrice_0,
            BettingContract.Direction direction_0
        ) = betting.bets(0);
        assertEq(
            acceptor,
            acceptorAdr,
            "Acceptor address not updated correctly"
        );
        assertEq(isActive_0, true, "Bet should be active after acceptance");
        // Verify that the token amount has been transferred to the contract
        assertEq(
            token.balanceOf(address(betting)),
            expectedTotalBetAmount,
            "Token balance not updated correctly"
        );
    }

    function testSettleBetProposerWins() public {
        // Create a new bet
        uint256 expirationTime = block.timestamp + 86400; // 1 day from now
        uint256 closingTime = block.timestamp + 172800; // 2 days from now
        uint256 expectedTotalBetAmount = 2 * betAmount;
        uint256 expectedFee = (expectedTotalBetAmount * 2) / 100;
        uint256 expectedWinnings = expectedTotalBetAmount - expectedFee;
        BettingContract.Direction direction = BettingContract.Direction.Long;

        // Mock the call to chainlink the orcale wotn owkr when we jump into the future
        vm.mockCall(
            address(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43),
            abi.encodeWithSelector(
                AggregatorV3Interface.latestRoundData.selector
            ),
            abi.encode(1, 1, 1, 1, 1)
        );

        // Give acceptor some eth
        vm.deal(acceptorAdr, 1 ether);
        deal(tokenAddress, acceptorAdr, betAmount);

        // Give proposer usdc and approve the betting contract to spend it
        vm.prank(proposerAdr);
        token.approve(address(betting), betAmount);
        deal(tokenAddress, proposerAdr, betAmount);

        // Give acceptor usdc and approve the betting contract to spend it
        vm.prank(acceptorAdr);
        token.approve(address(betting), betAmount);
        deal(tokenAddress, acceptorAdr, betAmount);

        vm.prank(proposerAdr);
        betting.proposeBet(expirationTime, closingTime, betAmount, direction);
        
        console.log("Acceptor Before",token.balanceOf(acceptorAdr));

        // Accept the bet
        vm.prank(acceptorAdr);
        betting.acceptBet(0);

        
        console.log("Acceptor After",token.balanceOf(acceptorAdr));

        // Settle the bet after the closing time has elapsed
        uint256 settlementTime = closingTime + 3600; // 1 hour after closing time

        // Helper function to simulate the passage of time
        skip(1000000000);

        vm.startPrank(settlerAdr);
        // vm.expectEmit(address(betting));
        // emit BetClosed(0, proposerAdr, expectedWinnings);
        betting.settleBet(0);

        console.log("Acceptor After",token.balanceOf(acceptorAdr));



        // Verify that the bet state has been updated correctly
        (
            ,
            address acceptor,
            uint256 amount_0,
            uint256 expirationTime_0,
            uint256 closingTime_0,
            bool isActive_0,
            uint256 openingPrice_0,
            uint256 closingPrice_0,
            BettingContract.Direction direction_0
        ) = betting.bets(0);
        assertEq(isActive_0, false, "Bet should be active after acceptance");

        // Assert that the BetClosed event was emitted successfully

        // Assert that the winnings have been transferred to the correct winner and the fee has been transferred to the owner
        assertEq(
            token.balanceOf(proposerAdr),
            expectedWinnings,
            "proposer balance incorrect"
        );

        // Acceptor looses so has 0 balance
        assertEq(token.balanceOf(acceptorAdr), 0, "acceptor balance incorrect");
    }
}
