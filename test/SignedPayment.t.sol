// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { Deploy } from "../script/Deploy.s.sol";
import { SignedPayment } from "../src/SignedPayment.sol";
import { ERC20Mock } from "../src/mocks/ERC20Mock.sol";
import { EIP712 } from "../src/libraries/EIP712.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract SignedPaymentTest is Test {
  address public OWNER = makeAddr("OWNER");
  Account public SIGNER = makeAccount("SIGNER");
  uint256 public TOKEN_BALANCE = 100 * 10 ** 18;
  uint256 public PAYMENT_AMOUNT = 10 * 10 ** 18;
  address public SENDER = makeAddr("SENDER");
  uint256 public DEADLINE_ADDJUST = 1 minutes;

  SignedPayment signedPayment;
  ERC20Mock token;

  function setUp() public {
    Deploy deployer = new Deploy();
    (signedPayment, token) = deployer.deploy(OWNER, SIGNER.addr);
  }

  function test_setup_success() public view {
    assertEq(signedPayment.s_tokens(IERC20(token)), true);
    assertEq(signedPayment.owner(), OWNER);
    assertEq(signedPayment.s_signer(), SIGNER.addr);
  }

  function test_receivePayment_suceess() public {
    // send test token to the contract
    token.mint(address(signedPayment), TOKEN_BALANCE);

    // get the nonce of the sender and set deadline
    uint256 nonce = signedPayment.getUserNonce(SENDER);
    uint256 deadline = block.timestamp + DEADLINE_ADDJUST;

    // sign the params
    DataTypes.PayParams memory params = getPaymentSignedBy(
      DataTypes.PayEIP712Params({
        nonce: nonce,
        deadline: deadline,
        amount: PAYMENT_AMOUNT,
        receiver: SENDER,
        token: address(token)
      }),
      SIGNER
    );

    vm.prank(SENDER);
    signedPayment.receivePayment(params);

    assertEq(token.balanceOf(SENDER), PAYMENT_AMOUNT);
    assertEq(token.balanceOf(address(signedPayment)), TOKEN_BALANCE - PAYMENT_AMOUNT);
    assertEq(signedPayment.getUserNonce(SENDER), nonce + 1);
  }

  function test_receivePayment_reverts_whenSignatureUsedTwice() public {
    // send test token to the contract
    token.mint(address(signedPayment), TOKEN_BALANCE);

    // get the nonce of the sender and set deadline
    uint256 nonce = signedPayment.getUserNonce(SENDER);
    uint256 deadline = block.timestamp + DEADLINE_ADDJUST;

    // sign the params
    DataTypes.PayParams memory params = getPaymentSignedBy(
      DataTypes.PayEIP712Params({
        nonce: nonce,
        deadline: deadline,
        amount: PAYMENT_AMOUNT,
        receiver: SENDER,
        token: address(token)
      }),
      SIGNER
    );

    vm.startPrank(SENDER);
    signedPayment.receivePayment(params);

    vm.expectRevert(Errors.EIP712__InvalidSignature.selector);
    signedPayment.receivePayment(params);
    vm.stopPrank();
  }

  function test_receivePayment_reverts_whenDeadlineExpired() public {
    // send test token to the contract
    token.mint(address(signedPayment), TOKEN_BALANCE);

    // get the nonce of the sender and set deadline
    uint256 nonce = signedPayment.getUserNonce(SENDER);
    uint256 deadline = block.timestamp + DEADLINE_ADDJUST;

    // sign the params
    DataTypes.PayParams memory params = getPaymentSignedBy(
      DataTypes.PayEIP712Params({
        nonce: nonce,
        deadline: deadline,
        amount: PAYMENT_AMOUNT,
        receiver: SENDER,
        token: address(token)
      }),
      SIGNER
    );

    vm.warp(deadline + DEADLINE_ADDJUST);
    vm.expectRevert(Errors.EIP712__ExpiredSignature.selector);
    signedPayment.receivePayment(params);
  }

  function test_receivePayment_reverts_whenTokenIsNotValid() public {
    // get the nonce of the sender and set deadline
    uint256 nonce = signedPayment.getUserNonce(SENDER);
    uint256 deadline = block.timestamp + DEADLINE_ADDJUST;

    // sign the params
    address invalidToken = makeAddr("INVALID_TOKEN");
    DataTypes.PayParams memory params = getPaymentSignedBy(
      DataTypes.PayEIP712Params({
        nonce: nonce,
        deadline: deadline,
        amount: PAYMENT_AMOUNT,
        receiver: SENDER,
        token: invalidToken
      }),
      SIGNER
    );

    vm.expectRevert(abi.encodeWithSelector(Errors.SignedPayment__TokenIsNotValid.selector, invalidToken));
    signedPayment.receivePayment(params);
  }

  function test_receivePayment_reverts_whenBalanceIsLow() public {
    token.mint(address(signedPayment), TOKEN_BALANCE);
    uint256 nonce = signedPayment.getUserNonce(SENDER);
    uint256 deadline = block.timestamp + DEADLINE_ADDJUST;

    // sign the params
    uint256 requestedAmount = TOKEN_BALANCE + 1;
    DataTypes.PayParams memory params = getPaymentSignedBy(
      DataTypes.PayEIP712Params({
        nonce: nonce,
        deadline: deadline,
        amount: requestedAmount,
        receiver: SENDER,
        token: address(token)
      }),
      SIGNER
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        Errors.SignedPayment__NotEnoughBalance.selector, address(token), TOKEN_BALANCE, requestedAmount
      )
    );
    signedPayment.receivePayment(params);
  }

  function test_receivePayment_reverts_whenPaused() public {
    token.mint(address(signedPayment), TOKEN_BALANCE);

    vm.prank(OWNER);
    signedPayment.pause();

    uint256 nonce = signedPayment.getUserNonce(SENDER);
    uint256 deadline = block.timestamp + DEADLINE_ADDJUST;

    // sign the params
    DataTypes.PayParams memory params = getPaymentSignedBy(
      DataTypes.PayEIP712Params({
        nonce: nonce,
        deadline: deadline,
        amount: PAYMENT_AMOUNT,
        receiver: SENDER,
        token: address(token)
      }),
      SIGNER
    );

    vm.expectRevert(Pausable.EnforcedPause.selector);
    signedPayment.receivePayment(params);
  }

  /*//////////////////////////////////////////////////////////////
                              HELPERS
  //////////////////////////////////////////////////////////////*/

  function getPaymentSignedBy(
    DataTypes.PayEIP712Params memory _params,
    Account memory _signer
  )
    public
    view
    returns (DataTypes.PayParams memory)
  {
    bytes32 structHash = EIP712.buildTypedDataHash(
      signedPayment.i_domainSeparator(),
      keccak256(
        abi.encode(
          signedPayment.PAYMENT_RECEIVE_EIP712_TYPEHASH(),
          _params.nonce,
          _params.deadline,
          _params.amount,
          _params.receiver,
          _params.token
        )
      )
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signer.key, structHash);

    return DataTypes.PayParams({
      deadline: _params.deadline,
      amount: _params.amount,
      token: _params.token,
      s: s,
      r: r,
      v: v
    });
  }
}
