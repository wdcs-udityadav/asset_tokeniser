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

    event PropertyListed(
        uint256 indexed propertyId, address indexed owner, uint256 valuation, uint256 indexed investibleAmount
    );

    event Invested(uint256 propertyId, uint256 amountInvested, address investor);

    function setUp() public {
        assetTokenizer = new AssetTokenizer();
        assetNFT = assetTokenizer._assetNFT();
        assetToken = assetTokenizer._assetToken();

        usdt = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    function testPropertyListed() public {
        assetTokenizer.listProperty(1, 1000, 10, 100000);

        assertEq(assetNFT.ownerOf(1), address(this));
        assertEq(assetToken.balanceOf(address(this)), 100);
    }

    function testEmitPropertyListed() public {
        vm.expectEmit(true, true, false, true);
        emit PropertyListed(1, address(this), 1000, 100);
        assetTokenizer.listProperty(1, 1000, 10, 100000);
    }

    function testInvestInProperty() public {
        address propertyOwner = vm.addr(1);
        address investor = vm.addr(2);
        console.log("investor: ", investor);
        console.log("propertyOwner: ", propertyOwner);
        console.log("address(this): ", address(this));

        console.log("Balance of investor: ", usdt.balanceOf(investor)/1e18);
        deal(address(usdt), investor, 100 * 1e18, true);
        console.log("Balance of investor: ", usdt.balanceOf(investor)/1e18);

        vm.startPrank(propertyOwner);
        assetTokenizer.listProperty(1, 1000*1e18, 10, 100000*1e18);
        assertEq(assetNFT.ownerOf(1), propertyOwner);
        console.log("owner",assetNFT.ownerOf(1));
        console.log("Balance of proper: ", usdt.balanceOf(investor)/1e18);

        assertEq(assetToken.balanceOf(propertyOwner), 100*1e18);
        assertTrue(assetToken.approve(address(assetTokenizer), 100*1e18));
        vm.stopPrank();

        vm.startPrank(investor, investor);
        console.log("Balance of investor: ", usdt.balanceOf(investor)/1e18);
        bool result = usdt.approve(address(assetTokenizer), 100*1e18);
        assertTrue(result);
        console.log("result: ", result);

        assetTokenizer.investInProperty(1, 100*1e18);
        console.log("usdt balance investor: ", usdt.balanceOf(investor)/1e18);
        console.log("token balance investor: ", assetToken.balanceOf(investor)/1e18);
        console.log("token balance propertyOwner: ", assetToken.balanceOf(propertyOwner)/1e18);
        assertEq(assetToken.balanceOf(propertyOwner), 0);
        assertEq(assetToken.balanceOf(investor), 100*1e18);
        vm.stopPrank();
    }

    // function testEmitInvested() public {
    //     address propertyOwner = vm.addr(1);
    //     address investor = vm.addr(2);
    //     console.log("balance: ", usdt.balanceOf(investor)/1e6);
    //     console.log("totalSupply: ", usdt.totalSupply()/1e6);

    //     deal(address(usdt), investor, 100*1e6, true);
    //     console.log("balance: ", usdt.balanceOf(investor)/1e6);
    //     console.log("totalSupply: ", usdt.totalSupply()/1e6);

    //     vm.startPrank(propertyOwner);
    //     assetTokenizer.listProperty(1, 1000, 10, 100000);
    //     assetToken.approve(address(assetTokenizer), 100);
    //     vm.stopPrank();

    //     vm.expectEmit(true, true, true,false);
    //     emit Invested(1, 100, address(this));

    //     vm.startPrank(investor);
    //     usdt.approve(address(assetTokenizer), 100);
    //     assetTokenizer.investInProperty(1, 100);
    //     vm.stopPrank();
    // }
}
