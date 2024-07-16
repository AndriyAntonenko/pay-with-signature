// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
  /*//////////////////////////////////////////////////////////////
                            DOMAIN ERRORS
  //////////////////////////////////////////////////////////////*/

  error SignedPayment__TokenIsNotValid(address token);
  error SignedPayment__NotEnoughBalance(address token, uint256 balance, uint256 amount);
  error SignedPayment__ZeroAddress();
  error SignedPayment__ZeroAmount();
  error SignedPayment__TokenAlreadyAdded(address token);

  /*//////////////////////////////////////////////////////////////
                            EIP712 ERRORS
  //////////////////////////////////////////////////////////////*/

  error EIP712__ExpiredSignature();
  error EIP712__InvalidSignature();
}
