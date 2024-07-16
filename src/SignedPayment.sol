// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { DataTypes } from "./libraries/DataTypes.sol";
import { EIP712 } from "./libraries/EIP712.sol";
import { Errors } from "./libraries/Errors.sol";
import { ISignedPayment } from "./interfaces/ISignedPayment.sol";

contract SignedPayment is ISignedPayment, Ownable, Pausable {
  /*//////////////////////////////////////////////////////////////
                              CONSTANTS
  //////////////////////////////////////////////////////////////*/

  bytes32 public constant PAYMENT_RECEIVE_EIP712_TYPEHASH =
    keccak256("PayEIP712Params(uint256 nonce,uint256 deadline,uint256 amount,address receiver,address token)");

  bytes32 public immutable i_domainSeparator;

  /*//////////////////////////////////////////////////////////////
                                STATE
  //////////////////////////////////////////////////////////////*/

  address public s_signer;
  mapping(address => uint256) public s_nonces;
  mapping(IERC20 => bool) public s_tokens;

  /*//////////////////////////////////////////////////////////////
                              MODIFIERS
  //////////////////////////////////////////////////////////////*/

  constructor(address _owner, address _signer, address _initialToken) Ownable(_owner) Pausable() {
    s_signer = _signer;
    i_domainSeparator = EIP712.buildDomainSeparator(
      EIP712.EIP712Domain({
        name: "SignedPayment",
        version: "1",
        chainId: block.chainid,
        verifyingContract: address(this),
        salt: 0
      })
    );

    if (_initialToken != address(0)) {
      s_tokens[IERC20(_initialToken)] = true;
    }
  }

  function getUserNonce(address _user) external view returns (uint256) {
    return _getNonce(_user);
  }

  function receivePayment(DataTypes.PayParams memory _params) external whenNotPaused {
    uint256 nonce = _getNonce(msg.sender);

    if (_params.amount == 0) {
      revert Errors.SignedPayment__ZeroAmount();
    }

    if (s_tokens[IERC20(_params.token)] == false) {
      revert Errors.SignedPayment__TokenIsNotValid(address(_params.token));
    }

    uint256 balance = IERC20(_params.token).balanceOf(address(this));
    if (balance < _params.amount) {
      revert Errors.SignedPayment__NotEnoughBalance(address(_params.token), balance, _params.amount);
    }

    DataTypes.PayEIP712Params memory eip712Params = DataTypes.PayEIP712Params({
      nonce: nonce,
      deadline: _params.deadline,
      amount: _params.amount,
      receiver: msg.sender,
      token: _params.token
    });

    bytes32 typeDataHash = _getTypeDataHashForReceivePayment(eip712Params);

    EIP712.validateSignature(s_signer, typeDataHash, _params.deadline, _params.v, _params.r, _params.s);

    _incrementNonce(msg.sender);
    IERC20(_params.token).transfer(msg.sender, _params.amount);
    emit PaymentSent(msg.sender, _params.token, _params.amount);
  }

  function _getNonce(address _user) internal view returns (uint256) {
    return s_nonces[_user] + 1;
  }

  function _incrementNonce(address _user) internal {
    s_nonces[_user]++;
  }

  function _getTypeDataHashForReceivePayment(DataTypes.PayEIP712Params memory _params) internal view returns (bytes32) {
    return EIP712.buildTypedDataHash(
      i_domainSeparator,
      keccak256(
        abi.encode(
          PAYMENT_RECEIVE_EIP712_TYPEHASH,
          _params.nonce,
          _params.deadline,
          _params.amount,
          _params.receiver,
          _params.token
        )
      )
    );
  }

  /*//////////////////////////////////////////////////////////////
                              MANAGEMENT
  //////////////////////////////////////////////////////////////*/

  function addToken(IERC20 _token) external onlyOwner {
    if (address(_token) == address(0)) {
      revert Errors.SignedPayment__ZeroAddress();
    }

    if (s_tokens[_token] == true) {
      revert Errors.SignedPayment__TokenAlreadyAdded(address(_token));
    }
    s_tokens[_token] = true;
  }

  function removeToken(IERC20 _token) external onlyOwner {
    if (s_tokens[_token] == false) {
      revert Errors.SignedPayment__TokenIsNotValid(address(_token));
    }
    s_tokens[_token] = false;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setSigner(address _signer) external onlyOwner {
    if (_signer == address(0)) {
      revert Errors.SignedPayment__ZeroAddress();
    }
    s_signer = _signer;
  }
}
