// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AssetTokenizer} from "../src/AssetTokenizer.sol";
import {AssetNFT} from "../src/AssetNFT.sol";
import {AssetToken} from "../src/AssetToken.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract AssetTokenizerTest is Test {
    using SafeERC20 for IERC20;

    AssetTokenizer public assetTokenizer;
    AssetNFT public assetNFT;
    AssetToken public assetToken;

    IERC20 public usdt;

    error NoInvestmentFound();
    error AmountExceeds();
    error AlreadyInvested();
    error TryAfter24Hours();
    error DividentNoLongerCanBeClaimed();

    event PropertyListed(
        uint256 indexed propertyId, address indexed owner, uint256 valuation, uint256 indexed investibleAmount
    );
    event Invested(uint256 indexed propertyId, uint256 indexed amountInvested, address indexed investor);
    event DividendClaimed(uint256 indexed propertyId, uint256 indexed amount, address indexed investor);

    function setUp() public {
        assetTokenizer = new AssetTokenizer();
        assetNFT = assetTokenizer._assetNFT();
        assetToken = assetTokenizer._assetToken();

        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); //USDT on mainnet
    }

    function testPropertyListed() public {
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);

        assertEq(assetNFT.ownerOf(1), address(this));
        assertEq(assetToken.balanceOf(address(this)), 100 * 1e6);
    }

    function testPropertyListedFailIfValueSentUnequal() public {
        vm.expectRevert(bytes("msg.value must be equal to rentalincome"));
        assetTokenizer.listProperty{value: 10}(1, 1000 * 1e6, 10, 100000 * 1e6);
    }

    function testEmitPropertyListed() public {
        vm.expectEmit(true, true, false, true);
        emit PropertyListed(1, address(this), 1000 * 1e6, 100 * 1e6);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
    }

    function testInvestInProperty() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 100 * 1e6);
        assetTokenizer.investInProperty(1, 100 * 1e6);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e6);
        vm.stopPrank();
    }

    function testInvestInPropertyFailIfAmountExceeds() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 200 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 200 * 1e6);
        vm.expectRevert(AmountExceeds.selector);
        assetTokenizer.investInProperty(1, 200 * 1e6);
        vm.stopPrank();
    }

    function testInvestmentFailIfAlreadyInvested() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 100 * 1e6);
        assetTokenizer.investInProperty(1, 100 * 1e6);
        vm.expectRevert(AlreadyInvested.selector);

        assetTokenizer.investInProperty(1, 200 * 1e6);
        vm.stopPrank();
    }

    function testEmitInvested() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 100 * 1e6);
        vm.expectEmit(true, true, true, false);
        emit Invested(1, 100 * 1e6, address(investor));
        assetTokenizer.investInProperty(1, 100 * 1e6);
        vm.stopPrank();
    }

    function testClaimDividendFailsBefore24Hours() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 100 * 1e6);
        assetTokenizer.investInProperty(1, 100 * 1e6);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e6);

        vm.expectRevert(TryAfter24Hours.selector);
        assetTokenizer.claimDividend(1);
        vm.stopPrank();
    }

    function testClaimDividendFailsIfNoInvestment() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        vm.expectRevert(NoInvestmentFound.selector);
        assetTokenizer.claimDividend(1);
    }

    function testClaimDividendFailsAfter365Days() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 100 * 1e6);
        assetTokenizer.investInProperty(1, 100 * 1e6);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e6);

        skip(366 * 1 days);
        vm.expectRevert(DividentNoLongerCanBeClaimed.selector);
        assetTokenizer.claimDividend(1);
        vm.stopPrank();
    }

    function testClaimDividend() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 100 * 1e6);
        assetTokenizer.investInProperty(1, 100 * 1e6);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e6);
        skip(1 days);
        assetTokenizer.claimDividend(1);
        vm.stopPrank();
    }

    function testEmitDividendClaimed() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e6, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e6}(1, 1000 * 1e6, 10, 100000 * 1e6);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e6);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e6));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.forceApprove(address(assetTokenizer), 100 * 1e6);
        assetTokenizer.investInProperty(1, 100 * 1e6);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e6);
        skip(1 days);
        vm.expectEmit(true, true, true, false);
        emit DividendClaimed(1, 27397260, address(investor));
        assetTokenizer.claimDividend(1);
        vm.stopPrank();
    }
}
