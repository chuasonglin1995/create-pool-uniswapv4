set dotenv-load := true

default:
    @just --choose

setup:
    forge install
    cp .env.example .env

create-pool:
    forge script script/CreatePool.s.sol:CreatePool --rpc-url $SEPOLIA_RPC_URL --private-key $WALLET_PRIVATE_KEY --sender $WALLET_PUBLIC_KEY --verify --etherscan-api-key $ETHERSCAN_API_KEY --broadcast -vvvv