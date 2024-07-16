// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
  constructor() ERC20("Mock", "MOCK") {
    _mint(msg.sender, 1_000_000 * 10 ** 18);
  }

  function mint(address _to, uint256 _amount) external {
    _mint(_to, _amount);
  }
}
