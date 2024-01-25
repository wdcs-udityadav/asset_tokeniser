// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AssetToken} from "./AssetToken.sol";
import {AssetNFT} from "./AssetNFT.sol";

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract AssetTokenizer {
    using SafeERC20 for IERC20;

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    AssetToken public _assetToken;
    AssetNFT public _assetNFT;

    struct Property {
        address propertyOwner;
        uint256 propertyId;
        uint256 valuation;
        uint256 investiblePercentage;
        uint256 rentalIncome;
        uint256 investibleAmount;
    }

    struct Investment {
        uint256 propertyId;
        uint256 amountInvested;
        address investor;
    }

    mapping(uint256 => Property) public listedProperties;
    mapping(uint256 => mapping(address => Investment)) public investments;

    event PropertyListed(
        uint256 indexed propertyId, 
        address indexed owner, 
        uint256 valuation, 
        uint256 indexed investibleAmount
    );

    event Invested(uint256 propertyId, uint256 amountInvested, address investor);
    
    constructor() {
        _assetToken = new AssetToken(msg.sender);
        _assetNFT =  new AssetNFT(msg.sender); 
    }

    function listProperty(uint256 _propertyId, uint256 _valuation, uint256 _investiblePercentage, uint256 _rentalIncome) public {
        uint256 investibleAmount = (_investiblePercentage * _valuation) / 100;
        
        Property memory _property = Property(
                msg.sender,
                _propertyId,
                _valuation,
                _investiblePercentage,
                _rentalIncome,
                investibleAmount
            );

        listedProperties[_propertyId] = _property;

        //mint nft and tokens
        _assetNFT.mint(msg.sender, "assset nft");
        _assetToken.mint(msg.sender, investibleAmount);

        emit PropertyListed(_propertyId, msg.sender, _valuation, investibleAmount);
    }

    function investInProperty(uint256 _propertyId, uint256 _amount) public {
        Investment memory _investment = Investment(
            _propertyId,
            _amount, 
            msg.sender
        );

        address propertyOwner = listedProperties[_propertyId].propertyOwner;
        IERC20(USDT).safeTransferFrom(msg.sender, propertyOwner, _amount);
        investments[_propertyId][msg.sender] = _investment;

        IERC20(_assetToken).safeTransferFrom(propertyOwner, msg.sender, _amount);

        emit Invested(_propertyId, _amount, msg.sender);
    }

    function claimDividend() public {
        
    }
}
