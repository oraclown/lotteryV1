// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import {stdCheats} from "forge-std/stdlib.sol";
import "../LotteryV1.sol";
import "forge-std/console.sol";

contract ContractTest is DSTest, stdCheats {
    LotteryV1 private lottery;
    Vm vm = Vm(HEVM_ADDRESS);

    address alice = address(0x12341234);
    address bob = address(0x67896789);
    address cletus = address(0x12345678);

    uint256 public MAX_TICKETS = 100;
    uint256 public TICKET_PRICE = 1;
    uint256 public BUY_PERIOD = 60 * 60; // 1 hour
    uint256 public ADMIN_FEE = 1; // 1%

    function setUp() public {
        vm.deal(cletus, 1 ether);
        vm.prank(cletus);
        lottery = new LotteryV1(
            MAX_TICKETS,
            TICKET_PRICE,
            BUY_PERIOD,
            ADMIN_FEE
        );

        vm.label(address(lottery), "TestLottery");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");
    }

    function test_deployContract() public {
        assertTrue(!lottery.payWinnerCalled());
        assertEq(address(lottery).balance, 0);
        assertEq(lottery.maxTickets(), MAX_TICKETS);
        assertEq(lottery.ticketPrice(), TICKET_PRICE);
        assertEq(lottery.lotteryStart(), block.timestamp);
        assertEq(lottery.lotteryEnd(), block.timestamp + BUY_PERIOD);
        assertEq(lottery.forTheBoyz(), ADMIN_FEE);
        assertEq(lottery.ticketsBought(), 0);
        assertEq(lottery.admin(), cletus);
        assertEq(lottery.winner(), address(0));
    }

    function testDeployLotteryFail() public {
        startHoax(bob);

        vm.expectRevert("Max tickets must be greater than 0");
        new LotteryV1(0, TICKET_PRICE, BUY_PERIOD, ADMIN_FEE);

        vm.expectRevert("Ticket price must be greater than 0");
        new LotteryV1(MAX_TICKETS, 0, BUY_PERIOD, ADMIN_FEE);

        vm.expectRevert("Buy period must be at least 1 hour");
        new LotteryV1(MAX_TICKETS, TICKET_PRICE, 0, ADMIN_FEE);

        vm.expectRevert("Admin fee must be 0-100, representing 0-100%");
        new LotteryV1(MAX_TICKETS, TICKET_PRICE, BUY_PERIOD, 101);

        vm.stopPrank();
    }

    function testBuyTicket() public {
        startHoax(alice);

        uint256 startBalance = alice.balance;
        lottery.buyTicket{value: TICKET_PRICE}();
        uint256 endBalance = alice.balance;

        assertEq(startBalance - TICKET_PRICE, endBalance);
        assertEq(lottery.ticketsBought(), 1);
        assertEq(address(lottery).balance, TICKET_PRICE);
        assertEq(lottery.ticketBuyers(0), alice);

        vm.stopPrank();
    }

    function testBuyTicketFail() public {
        startHoax(alice);

        vm.expectRevert("Ticket purchase underpriced");
        lottery.buyTicket{value: 0}();

        for (uint256 i = 0; i < MAX_TICKETS; i++) {
            lottery.buyTicket{value: TICKET_PRICE}();
        }
        vm.expectRevert("No more tickets left");
        lottery.buyTicket{value: TICKET_PRICE}();

        vm.warp(BUY_PERIOD + 1); // fast forward
        vm.expectRevert("Lottery is over");
        lottery.buyTicket{value: TICKET_PRICE}();

        vm.stopPrank();
    }

    function testChooseAndPayWinner() public {
        vm.roll(10); // Avoid arithmetic underflow when calculating block.number - 1

        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);

        uint256 aliceStartBalance = alice.balance;
        uint256 bobStartBalance = bob.balance;
        uint256 cletusStartBalance = cletus.balance;

        vm.startPrank(alice);
        for (uint256 i = 0; i < MAX_TICKETS; i++) {
            lottery.buyTicket{value: TICKET_PRICE}();
        }
        vm.stopPrank();
        uint256 pot = address(lottery).balance;
        vm.warp(BUY_PERIOD + 1); // fast forward

        vm.startPrank(bob);
        lottery.chooseWinner();
        lottery.payWinner();
        vm.stopPrank();

        uint256 aliceReward = alice.balance - aliceStartBalance;
        uint256 bobReward = bob.balance - bobStartBalance;

        assertEq(lottery.winner(), alice);
        assertTrue(lottery.payWinnerCalled());
        assertEq(bob.balance, bobStartBalance + TICKET_PRICE * 2);
        assertEq(address(lottery).balance, 0);
        console.log("Cletus balance", cletus.balance);
        console.log("Pot", pot);
        console.log("Alic balance", alice.balance);
        console.log("Bob balance", bob.balance);
        uint256 adminPayout = pot - aliceReward - bobReward;
        assertEq(cletus.balance, cletusStartBalance + adminPayout);
    }

    function testChooseWinnerFail() public {
        startHoax(alice);
        vm.expectRevert("Lottery not over");
        lottery.chooseWinner();
        vm.stopPrank();
    }

    function testPayWinnerFail() public {
        startHoax(alice);
        vm.expectRevert("Choose winner first");
        lottery.payWinner();
        vm.stopPrank();
    }
}
