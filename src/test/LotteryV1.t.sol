// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "../LotteryV1.sol";

interface CheatCodes {
    function prank(address) external;
    function expectRevert(bytes4) external;
}

contract ContractTest is DSTest {
    LotteryV1 private lottery;
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    uint256 public MAX_TICKETS = 100;
    uint256 public TICKET_PRICE = 1;
    uint256 public BUY_PERIOD = 60*60; // 1 hour
    uint256 public ADMIN_FEE = 1; // 1%

    function setUp() public {
        lottery = new LotteryV1(MAX_TICKETS, TICKET_PRICE, BUY_PERIOD, ADMIN_FEE);
    }

    function testDeployContract() public {
        assertTrue(!lottery.payWinnerCalled());
        assertEq(address(lottery).balance, 0);
        assertEq(lottery.maxTickets(), MAX_TICKETS);
        assertEq(lottery.ticketPrice(), TICKET_PRICE);
        assertEq(lottery.lotteryStart(), block.timestamp);
        assertEq(lottery.lotteryEnd(), block.timestamp + BUY_PERIOD);
        assertEq(lottery.forTheBoyz(), ADMIN_FEE);
        assertEq(lottery.ticketsBought(), 0);
        assertEq(lottery.admin(), address(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84));
        assertEq(lottery.winner(), address(0));
    }

    function testBuyTicket() public {
        cheats.prank(address(1));
        cheats.expectRevert(bytes("Ticket purchase underpriced"));
        lottery.buyTicket{value: TICKET_PRICE};
        assertEq(lottery.ticketsBought(), 1);
        assertEq(address(lottery).balance, TICKET_PRICE);
        // assertEq(lottery.ticketBuyers(0), address(1));
    }
}
