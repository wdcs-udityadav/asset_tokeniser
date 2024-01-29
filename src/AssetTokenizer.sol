// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AssetToken} from "./AssetToken.sol";
import {AssetNFT} from "./AssetNFT.sol";

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
// import "forge-std/console.sol";

contract AssetTokenizer {
    using SafeERC20 for IERC20;

    address constant USDT = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //dai
    uint256 constant duration = 365 * 1 days;
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
        uint256 investedAt;
        uint256 percentageOfValuation;
    }

    mapping(uint256 => Property) public listedProperties;
    mapping(uint256 => mapping(address => Investment)) public investments;

    error NoInvestmentFound();
    error AmountExceeds();
    error AlreadyInvested();
    error TryAfter24Hours();
    error DividentNoLongerCanBeClaimed();

    event PropertyListed(
        uint256 indexed propertyId, address indexed owner, uint256 valuation, uint256 indexed investibleAmount
    );

    event Invested(uint256 indexed propertyId, uint256 indexed amountInvested, address indexed investor);

    event DividendClaimed(uint256 propertyId, uint256 amount, address investor);

    constructor() {
        _assetToken = new AssetToken(address(this));
        _assetNFT = new AssetNFT(address(this));
    }

    function listProperty(uint256 _propertyId, uint256 _valuation, uint256 _investiblePercentage, uint256 _rentalIncome)
        public
        payable
        returns (uint256)
    {
        require(
            _propertyId > 0 && _valuation > 0 && _investiblePercentage > 0 && _rentalIncome > 0,
            "Input must be greater than zero."
        );

        require(msg.value == _rentalIncome, "msg.value must be equal to rentalincome");

        uint256 investibleAmount = (_investiblePercentage * _valuation) / 100;

        Property memory _property =
            Property(msg.sender, _propertyId, _valuation, _investiblePercentage, _rentalIncome, investibleAmount);

        listedProperties[_propertyId] = _property;

        //mint nft and tokens
        _assetNFT.mint(msg.sender, "assset nft");
        _assetToken.mint(msg.sender, investibleAmount);

        emit PropertyListed(_propertyId, msg.sender, _valuation, investibleAmount);
        return _propertyId;
    }

    function investInProperty(uint256 _propertyId, uint256 _amount) public {
        if (investments[_propertyId][msg.sender].amountInvested > 0) revert AlreadyInvested();
        require(_amount > 0, "amount should be greater than zero.");
        if (_amount > listedProperties[_propertyId].investibleAmount) revert AmountExceeds();

        uint256 percentageOfValuation = (_amount * 100) / listedProperties[_propertyId].valuation;

        Investment memory _investment =
            Investment(_propertyId, _amount, msg.sender, block.timestamp, percentageOfValuation);

        address propertyOwner = listedProperties[_propertyId].propertyOwner;

        IERC20(USDT).safeTransferFrom(msg.sender, propertyOwner, _amount);
        investments[_propertyId][msg.sender] = _investment;
        listedProperties[_propertyId].investibleAmount -= _amount;

        IERC20(_assetToken).safeTransferFrom(propertyOwner, msg.sender, _amount);

        emit Invested(_propertyId, _amount, msg.sender);
    }

    function claimDividend(uint256 _propertyId) public {
        if (investments[_propertyId][msg.sender].amountInvested == 0) revert NoInvestmentFound();
        if (block.timestamp > investments[_propertyId][msg.sender].investedAt + duration) {
            revert DividentNoLongerCanBeClaimed();
        }

        uint256 elapsedTime = block.timestamp - investments[_propertyId][msg.sender].investedAt;
        if (elapsedTime < 1 days) revert TryAfter24Hours();

        uint256 dividendAmount = (
            listedProperties[_propertyId].rentalIncome * investments[_propertyId][msg.sender].percentageOfValuation
        ) / 100;
        uint256 dividendPerDay = dividendAmount / 365;

        payable(msg.sender).transfer(dividendPerDay);

        emit DividendClaimed(_propertyId, dividendPerDay, msg.sender);
    }
}
