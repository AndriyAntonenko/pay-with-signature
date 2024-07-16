# Payment by signature

This simple contract designed to allow users receive payments in ERC20 tokens supported by the `SignedPayment` contract, by off-chain approval (EIP712).

### Preparation

1. Make sure that you have `forge`, `node` and `npm` installed.
2. Install all external dependencies and compile the smart contracts
 ```bash
 make prepare
 ```

### Deployment

1. Setup deployer wallet securely
 ```bash
 make setup-deployer
 # after this enter the private key of deploy and setup the password for it
 ```

2. After this create `.env` file in the root of the project with envs defined in the `.env.example` file

3. Then, run the command below
 ```bash
 make deploy
 ```

### Interaction

You can generate signature to receive payment and optionally send the transaction with this signature using the command below

```bash
npm run generate-sig
```
