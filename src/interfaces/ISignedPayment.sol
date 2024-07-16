// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ISignedPayment {
  event PaymentSent(address indexed receiver, address indexed token, uint256 amount);

  /// @notice Send a payment to a receiver
  /// @dev This method MUST emit PaymentSent event
  /// @param _params The payment parameters
  function receivePayment(DataTypes.PayParams calldata _params) external;
}
