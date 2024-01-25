// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AssetTokenizer} from "../src/AssetTokenizer.sol";
import {AssetNFT} from "../src/AssetNFT.sol";
import {AssetToken} from "../src/AssetToken.sol";


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


    event PropertyListed(
        uint256 indexed propertyId, 
        address indexed owner, 
        uint256 valuation, 
        uint256 indexed investibleAmount
    );

    event Invested(
        uint256 propertyId,
        uint256 amountInvested,
        address investor
    );

    function setUp() public {
        assetTokenizer = new AssetTokenizer();
        assetNFT = assetTokenizer._assetNFT();
        assetToken = assetTokenizer._assetToken();

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

    // function testInvestInProperty() public {

    // }

    // function testEmitInvested() public {
    //     address propertyOwner = vm.addr(1);
    //     address investor = vm.addr(2);
        
    //     vm.expectEmit(true, true, true,false);
    //     emit Invested(1, 100, address(this));
    //     assetTokenizer.investInProperty(1, 100);
    // }
}
