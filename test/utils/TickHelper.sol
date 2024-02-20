pragma solidity =0.7.6;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

uint24 constant FEE_LOW = 500;
uint24 constant FEE_MEDIUM = 3000;
uint24 constant FEE_HIGH = 10000;

int24 constant TICK_LOW = 10;
int24 constant TICK_MEDIUM = 60;
int24 constant TICK_HIGH = 200;

// mapping(uint24 => int24)  feeAmountTickSpacing;
// feeAmountTickSpacing[500] = 10;
//         feeAmountTickSpacing[3000] = 60;
//         feeAmountTickSpacing[10000] = 200;

function getMinTick(int24 tickSpacing) pure returns (int24) {
	return (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
}

function getMaxTick(int24 tickSpacing) pure returns (int24) {
	return (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
}

function getTick(uint160 sqrtPriceX96) pure returns (int24) {
	return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
}
