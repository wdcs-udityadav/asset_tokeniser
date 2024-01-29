// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AssetTokenizer} from "../src/AssetTokenizer.sol";
import {AssetNFT} from "../src/AssetNFT.sol";
import {AssetToken} from "../src/AssetToken.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AssetTokenizerTest is Test {
    struct Property {
        address propertyOwner;
        uint256 propertyId;
        uint256 valuation;
        uint256 investiblePercentage;
        uint256 rentalIncome;
        uint256 investibleAmount;
    }

    AssetTokenizer public assetTokenizer;
    AssetNFT public assetNFT;
    AssetToken public assetToken;

    IERC20 public usdt;

    error TryAfter24Hours();

    event PropertyListed(
        uint256 indexed propertyId, address indexed owner, uint256 valuation, uint256 indexed investibleAmount
    );

    event Invested(uint256 indexed propertyId, uint256 indexed amountInvested, address indexed investor);

    event DividendClaimed(uint256 indexed propertyId, uint256 indexed amount, address indexed investor);

    function setUp() public {
        assetTokenizer = new AssetTokenizer();
        assetNFT = assetTokenizer._assetNFT();
        assetToken = assetTokenizer._assetToken();

        usdt = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    function testPropertyListed() public {
        assetTokenizer.listProperty{value: 100000 * 1e18}(1, 1000 * 1e18, 10, 100000 * 1e18);

        assertEq(assetNFT.ownerOf(1), address(this));
        assertEq(assetToken.balanceOf(address(this)), 100 * 1e18);
    }

    function testPropertyListedFailIfValueSentUnequal() public {
        vm.expectRevert(bytes("msg.value must be equal to rentalincome"));
        assetTokenizer.listProperty{value: 10}(1, 1000 * 1e18, 10, 100000 * 1e18);
    }

    function testEmitPropertyListed() public {
        vm.expectEmit(true, true, false, true);
        emit PropertyListed(1, address(this), 1000 * 1e18, 100 * 1e18);
        assetTokenizer.listProperty{value: 100000 * 1e18}(1, 1000 * 1e18, 10, 100000 * 1e18);
    }

    function testInvestInProperty() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e18, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e18}(1, 1000 * 1e18, 10, 100000 * 1e18);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e18);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e18));
        vm.stopPrank();

        vm.startPrank(investor);
        bool result = usdt.approve(address(assetTokenizer), 100 * 1e18);
        assertTrue(result);

        assetTokenizer.investInProperty(1, 100 * 1e18);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e18);
        vm.stopPrank();
    }

    function testEmitInvested() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);
        console.log("investor: ", investor);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100*1e18, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000*1e18}(1, 1000*1e18, 10, 100000*1e18);
        assertTrue(assetToken.approve(address(assetTokenizer), 100*1e18));
        vm.stopPrank();

        vm.startPrank(investor);
        usdt.approve(address(assetTokenizer), 100*1e18);
        vm.expectEmit(true, true, true, false);
        emit Invested(1, 100*1e18, address(investor));
        assetTokenizer.investInProperty(1, 100*1e18);
        vm.stopPrank();
    }

    function testClaimDividendFailsBefore24Hours() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e18, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e18}(1, 1000 * 1e18, 10, 100000 * 1e18);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e18);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e18));
        vm.stopPrank();

        vm.startPrank(investor);
        assertTrue(usdt.approve(address(assetTokenizer), 100 * 1e18));
        assetTokenizer.investInProperty(1, 100 * 1e18);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e18);

        vm.expectRevert(TryAfter24Hours.selector);
        assetTokenizer.claimDividend(1);
        vm.stopPrank();
    }

    function testClaimDividend() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e18, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e18}(1, 1000 * 1e18, 10, 100000 * 1e18);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e18);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e18));
        vm.stopPrank();

        vm.startPrank(investor);
        assertTrue(usdt.approve(address(assetTokenizer), 100 * 1e18));
        assetTokenizer.investInProperty(1, 100 * 1e18);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e18);
        skip(1 days);
        assetTokenizer.claimDividend(1);
        vm.stopPrank();
    }

    function testEmitDividendClaimed() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);

        vm.deal(propertyOwner, 100000 ether);
        deal(address(usdt), investor, 100 * 1e18, true);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty{value: 100000 * 1e18}(1, 1000 * 1e18, 10, 100000 * 1e18);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        assertEq(assetToken.balanceOf(propertyOwner), 100 * 1e18);
        assertTrue(assetToken.approve(address(assetTokenizer), 100 * 1e18));
        vm.stopPrank();

        vm.startPrank(investor);
        assertTrue(usdt.approve(address(assetTokenizer), 100 * 1e18));
        assetTokenizer.investInProperty(1, 100 * 1e18);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100 * 1e18);
        skip(1 days);
        vm.expectEmit(true, true, true, false);
        emit DividendClaimed(1, 27397260273972602739, address(investor));
        assetTokenizer.claimDividend(1);
        vm.stopPrank();
    }
}
