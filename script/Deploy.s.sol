// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { ERC20Mock } from "../src/mocks/ERC20Mock.sol";
import { SignedPayment } from "../src/SignedPayment.sol";

contract Deploy is Script {
  function run() public {
    address owner = vm.envAddress("OWNER");
    address signer = vm.envAddress("SIGNER");

    vm.startBroadcast();
    deploy(owner, signer);
    vm.stopBroadcast();
  }

  function deploy(address _owner, address _signer) public returns (SignedPayment, ERC20Mock) {
    ERC20Mock token = new ERC20Mock();
    SignedPayment signedPayment = new SignedPayment(_owner, _signer, address(token));
    return (signedPayment, token);
  }
}
