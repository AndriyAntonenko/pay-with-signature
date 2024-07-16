import { createPromptModule } from "inquirer";
import { Wallet, JsonRpcProvider, Contract } from "ethers";
import { parseSignature } from "viem";
import { config } from "dotenv";
import SignedPaymentOut from "../../out/SignedPayment.sol/SignedPayment.json" assert { type: "json" };

config();

if (!process.env.RPC_URL) {
  throw new Error("RPC_URL is required");
}

if (!process.env.SIGNED_PAYMENT_CONTRACT_ADDRESS) {
  throw new Error("SIGNED_PAYMENT_CONTRACT_ADDRESS is required");
}

if (!process.env.TOKEN_CONTRACT_ADDRESS) {
  throw new Error("TOKEN_CONTRACT_ADDRESS is required");
}

async function main() {
  const privateKeyPrompt = createPromptModule();

  const { privateKey: signerPrivateKey } = await privateKeyPrompt({
    type: "input",
    name: "privateKey",
    message: "Pls, enter signer private key (start with 0x):",
    validate: (answer) => {
      return /^0x[0-9a-fA-F]{64}$/.test(answer);
    },
  });

  const provider = new JsonRpcProvider(process.env.RPC_URL);
  const wallet = new Wallet(signerPrivateKey);
  const signer = wallet.connect(provider);

  const domain = {
    name: "SignedPayment",
    version: "1",
    chainId: (await provider.getNetwork()).chainId,
    verifyingContract: process.env.SIGNED_PAYMENT_CONTRACT_ADDRESS,
    salt: "0x0000000000000000000000000000000000000000000000000000000000000000",
  };

  const permit = {
    PayEIP712Params: [
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
      { name: "amount", type: "uint256" },
      { name: "receiver", type: "address" },
      { name: "token", type: "address" },
    ],
  };

  const { privateKey: senderPrivateKey } = await privateKeyPrompt({
    type: "input",
    name: "privateKey",
    message: "Pls, enter sender private key (start with 0x):",
    validate: (answer) => {
      return /^0x[0-9a-fA-F]{64}$/.test(answer);
    },
  });

  const senderWallet = new Wallet(senderPrivateKey);
  const sender = senderWallet.connect(provider);

  const signedPaymentContract = new Contract(
    process.env.SIGNED_PAYMENT_CONTRACT_ADDRESS,
    SignedPaymentOut.abi,
    sender
  );

  const nonce = await signedPaymentContract.getUserNonce(senderWallet.address);
  const block = await provider.getBlock();
  const deadline = block.timestamp + 60;
  const amount = 1;
  const signature = await signer.signTypedData(domain, permit, {
    nonce,
    deadline,
    amount,
    receiver: senderWallet.address,
    token: process.env.TOKEN_CONTRACT_ADDRESS,
  });

  console.log("Signature:", signature);

  const shouldSendTxPrompt = createPromptModule();
  const { shouldSendTx } = await shouldSendTxPrompt({
    type: "confirm",
    name: "shouldSendTx",
    message: "Do you want to send tx to the contract?",
  });

  if (!shouldSendTx) {
    return;
  }

  const { r, s, v } = parseSignature(signature);

  const tx = await signedPaymentContract.receivePayment({
    amount,
    deadline,
    token: process.env.TOKEN_CONTRACT_ADDRESS,
    r,
    s,
    v,
  });

  console.info("Waiting for tx to be mined...");

  await tx.wait();

  console.log("Tx sent successfully");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
