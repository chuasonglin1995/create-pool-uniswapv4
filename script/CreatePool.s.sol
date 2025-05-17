// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { MockERC20 } from "src/MockERC20.sol";

import { PoolKey } from "v4-core/types/PoolKey.sol";
import { Currency } from "v4-core/types/Currency.sol";
import { IHooks } from "v4-core/interfaces/IHooks.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IPoolManager } from "v4-core/interfaces/IPoolManager.sol";

import { console } from "forge-std/console.sol";

contract CreatePool is Script {
    function run() public {
        vm.startBroadcast();

        MockERC20 token1 = new MockERC20("SONG", "SONG", 18, 1_000_000 ether);
        console.log("Token deployed at: ", address(token1));

		/**
		 * 
		 * Pool: ETH - SONG
		 * Fee: 500 = 0.05%
		 * TickSpacing: 10
		 * Hooks: no hook contract yet
		 */

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(address(0)), // address(0) for native currency
            currency1: Currency.wrap(address(token1)),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });

        // floor(sqrt(token1 / token0) * 2^96)

        // 1 ETH = 1000 SONG
        uint256 amount0 = 1;
        uint256 amount1 = 1000;

        // If tokens decimals are not same
        // USDC = 6 decimals
        // Pool ETH - USDC
        // 1 ETH = 1000 USDC
        // amount0 = 1 ether; // 1+18 decimals
        // amount1 = 1000e6; // 1+6 decimals

        uint160 startingPrice = encodeSqrtRatioX96(amount1, amount0);

        int24 poolTick = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543).initialize(pool, startingPrice);

        console.log("Token deployed at: ", address(token1));
        console.log("Pool tick is: ", poolTick);

        vm.stopBroadcast();
    }

    /**
     * @notice Encode a price between token0 and token1 as a sqrt ratio x96
     * @notice In case when decimals are the same
     * do not use price including decimals
     * In case when decimals are not the same
     * use price including decimals
     * Example:
     * 1 ETH = 1000 USDC (USDC = 6 decimals)
     * 1 ETH = 1000e6 USDC
     * amount0 = 1 ether; // 1+18 decimals
     * amount1 = 1000e6; // 1000+6 decimals
     * @param amount1 The amount of token1 as a price
     * @param amount0 The amount of token0 as a price
     * @return sqrtPriceX96 The encoded price
     */
    function encodeSqrtRatioX96(uint256 amount1, uint256 amount0) internal pure returns (uint160 sqrtPriceX96) {
        require(amount0 > 0, "PriceMath: division by zero");
        // Multiply amount1 by 2^192 (left shift by 192) to preserve precision after the square root.
        uint256 ratioX192 = (amount1 << 192) / amount0;
        uint256 sqrtRatio = Math.sqrt(ratioX192);
        require(sqrtRatio <= type(uint160).max, "PriceMath: sqrt overflow");
        sqrtPriceX96 = uint160(sqrtRatio);
    }
}