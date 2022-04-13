// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "../LotteryV1.sol";


contract ContractTest is DSTest {
    LotteryV1 private lottery;
    Vm vm = Vm(HEVM_ADDRESS);
    MockERC20 token;

    address alice = address(0x12341234);
    address bob = address(0x67896789);

    uint256 public MAX_TICKETS = 100;
    uint256 public TICKET_PRICE = 1;
    uint256 public BUY_PERIOD = 60*60; // 1 hour
    uint256 public ADMIN_FEE = 1; // 1%

    function setUp() public {
        token = new MockERC20("TestToken", "TT0", 18);
        vm.label(address(token), "TestToken");

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "TestContract");

        token.mint(alice, 1e18);

        lottery = new LotteryV1(MAX_TICKETS, TICKET_PRICE, BUY_PERIOD, ADMIN_FEE);
        vm.label(address(lottery), "TestLottery");
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
        vm.startPrank(alice);
        assertEq(token.balanceOf(alice), 1e18);
        vm.expectRevert("Ticket purchase underpriced");
        lottery.buyTicket();
        vm.stopPrank();
        // assertEq(lottery.ticketsBought(), 1);
        // assertEq(address(lottery).balance, TICKET_PRICE);
        // assertEq(lottery.ticketBuyers(0), alice);
    }
}
