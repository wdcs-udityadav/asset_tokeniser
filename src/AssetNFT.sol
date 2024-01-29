//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
// import "forge-std/console.sol";//;

contract AssetNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIds;

    event Minted(uint256 tokenId, address to);

    constructor(address _owner) ERC721("AssetTokenizerNFT", "ANFT") Ownable(_owner) {}

    function mint(address to, string memory tokenURI) public onlyOwner {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit Minted(tokenId, to);
    }
}
