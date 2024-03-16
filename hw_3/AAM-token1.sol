// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract token1 is ERC20{

    constructor() ERC20("token1", "TK1") {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
        super.approve(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }

} 