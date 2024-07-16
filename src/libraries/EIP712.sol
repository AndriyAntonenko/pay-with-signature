// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { Errors } from "./Errors.sol";

library EIP712 {
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
    bytes32 salt;
  }

  function buildDomainSeparator(EIP712Domain memory _domain) internal pure returns (bytes32) {
    return keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"),
        keccak256(bytes(_domain.name)),
        keccak256(bytes(_domain.version)),
        _domain.chainId,
        _domain.verifyingContract,
        _domain.salt
      )
    );
  }

  function validateSignature(
    address _signer,
    bytes32 _typedDataHash,
    uint256 deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
    internal
    view
  {
    if (deadline < block.timestamp) {
      revert Errors.EIP712__ExpiredSignature();
    }

    address recovered = ECDSA.recover(_typedDataHash, _v, _r, _s);

    if (recovered != _signer) {
      revert Errors.EIP712__InvalidSignature();
    }
  }

  function buildTypedDataHash(bytes32 _domainSeparator, bytes32 _structHash) internal pure returns (bytes32) {
    return MessageHashUtils.toTypedDataHash(_domainSeparator, _structHash);
  }
}
