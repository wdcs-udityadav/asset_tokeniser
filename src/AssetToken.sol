//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AssetToken is ERC20, Ownable {
    event Minted(uint256 indexed amount, address indexed to);

    constructor(address _owner) ERC20("AssetToken", "ATN") Ownable(_owner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);

        emit Minted(amount, to);
    }
}
