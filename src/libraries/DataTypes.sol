// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library DataTypes {
  struct PayParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 deadline;
    uint256 amount;
    address token;
  }

  struct PayEIP712Params {
    uint256 nonce;
    uint256 deadline;
    uint256 amount;
    address receiver;
    address token;
  }
}
