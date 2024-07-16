// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { ERC20Mock } from "../src/mocks/ERC20Mock.sol";

contract DepositMockTokens is Script {
  function run() public {
    address signedPayment = vm.envAddress("SIGNED_PAYMENT_CONTRACT_ADDRESS");
    address token = vm.envAddress("TOKEN_CONTRACT_ADDRESS");

    vm.startBroadcast();
    ERC20Mock(token).mint(signedPayment, 1000 * 10 ** 18);
    vm.stopBroadcast();
  }
}
