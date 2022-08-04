// /contracts/RSS3.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RSS3 is ERC20 {
    constructor(address initialAccount) ERC20("RSS3", "RSS3") {
        _mint(initialAccount, 10 * 10 ** 8 * 10 ** 18);
    }
}

