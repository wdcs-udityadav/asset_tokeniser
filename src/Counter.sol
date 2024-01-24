// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

contract AssetTokeniser is ERC721 {
    struct Property {
        uint256 propertyId;
        uint256 valuation;
        uint256 investiblePercentage;
    }
    mapping(address => Property) public listedProperties;
    mapping(uint256 => address) public investment;
    constructor() ERC721("Asset Tokeniser", "ATR") {}

    function listProperty(uint256 _propertyId, uint256 _valuation, uint256 _investiblePercentage) external {
        listedProperties[msg.sender].propertyId = _propertyId;
        listedProperties[msg.sender].valuation = _valuation;
        listedProperties[msg.sender].investiblePercentage = _investiblePercentage;

        //mint nft and tokens
    }

    function investInProperty(uint256 _propertyId) public payable{
        investment[_propertyId] = msg.sender;
    }
}
