import { writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { config } from "dotenv";
import { JsonRpcProvider, Contract } from "ethers";
import SignedPaymentOut from "../../out/SignedPayment.sol/SignedPayment.json" assert { type: "json" };

config();

const __dirname = dirname(fileURLToPath(import.meta.url));

if (!process.env.RPC_URL) {
  throw new Error("RPC_URL is required");
}

if (!process.env.SIGNED_PAYMENT_CONTRACT_ADDRESS) {
  throw new Error("SIGNED_PAYMENT_CONTRACT_ADDRESS is required");
}

const FROM = 6322934;
const BATCH_SIZE = 200;

async function main() {
  const provider = new JsonRpcProvider(process.env.RPC_URL);

  const contract = new Contract(
    process.env.SIGNED_PAYMENT_CONTRACT_ADDRESS,
    SignedPaymentOut.abi,
    provider
  );

  const latestBlock = await provider.getBlockNumber();
  let fromBlock = FROM;
  let toBlock = fromBlock + BATCH_SIZE;

  console.log(`Start reading events from block ${fromBlock} to ${latestBlock}`);

  const result = [];
  while (fromBlock < latestBlock) {
    if (toBlock > latestBlock) {
      toBlock = latestBlock;
    }

    const events = await contract.queryFilter(
      "PaymentSent",
      fromBlock,
      toBlock
    );

    console.info(
      `Read ${events.length} events from block ${fromBlock} to ${toBlock}`
    );

    for (const event of events) {
      const eventObj = {
        receiver: event.args[0],
        token: event.args[1],
        amount: event.args[2].toString(),
      };

      result.push(eventObj);
    }

    fromBlock = toBlock + 1;
    toBlock = fromBlock + BATCH_SIZE;
  }

  const output = JSON.stringify(result, null, 2);
  await writeFile(join(__dirname, "../../events.json"), output);
  console.info("Done");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
