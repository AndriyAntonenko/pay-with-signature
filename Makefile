-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil deploy-anvil

FIRST_ANVIL_PRIVATE_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80


all: remove build test

# Clean the repo
clean :; forge clean

prepare :; forge build && npm install

# Remove modules
remove :; rm -rf ../.gitmodules && rm -rf ../.git/modules/* && rm -rf lib && touch ../.gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

coverage :; forge coverage --ir-minimum

coverage-report :; forge coverage --ir-minimum --report debug > coverage-report.txt

slither :; slither . --config-file slither.config.json

setup-deployer :; cast wallet import --interactive pay-with-sig-deployer

deployer-address :; cast wallet address --account pay-with-sig-deployer

deploy :; forge script script/Deploy.s.sol \
	--account pay-with-sig-deployer \
	--rpc-url ${RPC_URL} \
	--legacy \
	--verify \
	--etherscan-api-key ${ETHERSCAN_API_KEY} \
	--broadcast

deploy-anvil :; forge script script/Deploy.s.sol \
	--private-key ${FIRST_ANVIL_PRIVATE_KEY} \
	--rpc-url http://localhost:8545 \
	--broadcast

deposit-mock-erc20 :; forge script script/DepositMockTokens.s.sol \
	--account pay-with-sig-deployer \
	--rpc-url ${RPC_URL} \
	--legacy \
	--broadcast

deposit-mock-erc20-anvil :; forge script script/DepositMockTokens.s.sol \
	--private-key ${FIRST_ANVIL_PRIVATE_KEY} \
	--rpc-url http://localhost:8545 \
	--broadcast

aderyn :; aderyn .

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 10 --chain-id 1337
