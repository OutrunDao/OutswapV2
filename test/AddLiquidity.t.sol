//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { console2 } from "forge-std/Test.sol";
import { BaseDeploy } from "test/utils/BaseDeploy.sol";

import { TransferHelper } from "contracts/v3-periphery/libraries/TransferHelper.sol";
import { INonfungiblePositionManager } from "contracts/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "test/utils/TickHelper.sol";
import { encodePriceSqrt } from "test/utils/Math.sol";
import { TransferHelper } from "contracts/v3-periphery/libraries/TransferHelper.sol";

import { ProviderLiquidity } from "src/ProviderLiquidity.sol";
import { SimpleSwap } from "src/SimpleSwap.sol";

/* 通过ProviderLiquidity.sol进行测试 */
/* 
uint24 constant FEE_LOW = 500;
uint24 constant FEE_MEDIUM = 3000;
uint24 constant FEE_HIGH = 10000;

int24 constant TICK_LOW = 10;
int24 constant TICK_MEDIUM = 60;
int24 constant TICK_HIGH = 200;
 */
contract SimpleSwapTest is BaseDeploy {
	/*  State varies */
	ProviderLiquidity public providerLiquidity;

	struct Deposit {
		address owner;
		uint128 liquidity;
		address token0;
		address token1;
	}

	/// @dev deposits[tokenId] => Deposit
	mapping(uint256 => Deposit) public deposits;

	/* 
    初始化：建立好一个测试环境，包括部署池子工厂合约，创建测试代币，创建测试账户等。
     */
	function setUp() public override {
		super.setUp();
		vm.startPrank(deployer);
		providerLiquidity = new ProviderLiquidity(nonfungiblePositionManager);
		// 针对tokens[1],toekns[2] 创建3个池子
		mintNewPool(tokens[1], tokens[2], FEE_LOW, INIT_PRICE);
		mintNewPool(tokens[1], tokens[2], FEE_MEDIUM, INIT_PRICE);
		mintNewPool(tokens[1], tokens[2], FEE_HIGH, INIT_PRICE);
		console2.log(uint256(INIT_PRICE));
		IERC20(tokens[1]).transfer(
			address(providerLiquidity),
			type(uint256).max / 4
		);
		IERC20(tokens[2]).transfer(
			address(providerLiquidity),
			type(uint256).max / 4
		);

		vm.stopPrank();
	}

	/* 简单测试 tick边界测试的是max & min*/
	function test_simpleMintNewPosition() public {
		uint256 amount0ToMint = 10000;
		uint256 amount1ToMint = 10000;
		vm.startPrank(deployer);

		providerLiquidity.mintNewPosition(
			tokens[1],
			tokens[2],
			TICK_LOW,
			getMinTick(TICK_LOW),
			getMaxTick(TICK_LOW),
			amount0ToMint,
			amount1ToMint
		);
		vm.stopPrank();
	}

	function test_ProviderLiquidity() public {
		uint256 amount0ToMint = 10000;
		uint256 amount1ToMint = 10000;
		vm.startPrank(deployer);

		(
			uint256 tokenId,
			uint128 liquidity,
			uint256 amount0,
			uint256 amount1
		) = providerLiquidity.mintNewPosition(
				tokens[1],
				tokens[2],
				TICK_LOW,
				getMinTick(TICK_LOW),
				getMaxTick(TICK_LOW),
				amount0ToMint,
				amount1ToMint
			);
		providerLiquidity.decreaseLiquidityInHalf(tokenId);
		vm.stopPrank();
	}


	function test_mintNewPosition_fail() public {}

	// function singlePoolExactInput(
	// 	address[] memory tokens,
	// 	uint256 amountIn,
	// 	uint256 amountOutMinimum
	// ) public {
	// 	vm.startPrank(trader);

	// 	bool inputIsWETH = tokens[0] == address(weth9);
	// 	bool outputIsWETH = tokens[tokens.length - 1] == address(weth9);
	// 	uint256 value = inputIsWETH ? amountIn : 0;

	// 	uint24[] memory fees = new uint24[](tokens.length - 1);
	// 	for (uint256 i = 0; i < fees.length; i++) {
	// 		fees[i] = FEE_MEDIUM;
	// 	}

	// 	ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
	// 		path: encodePath(tokens, fees),
	// 		recipient: outputIsWETH ? address(0) : trader,
	// 		deadline: 1,
	// 		amountIn: amountIn,
	// 		amountOutMinimum: amountOutMinimum
	// 	});

	// 	bytes[] memory data;
	// 	bytes memory inputs = abi.encodeWithSelector(
	// 		router.exactInput.selector,
	// 		params
	// 	);
	// 	if (outputIsWETH) {
	// 		data = new bytes[](2);
	// 		data[0] = inputs;
	// 		data[1] = abi.encodeWithSelector(
	// 			router.unwrapWETH9.selector,
	// 			amountOutMinimum,
	// 			trader
	// 		);
	// 	}

	// 	// ensure that the swap fails if the limit is any higher
	// 	params.amountOutMinimum += 1;
	// 	vm.expectRevert(bytes("Too little received"));
	// 	router.exactInput{ value: value }(params);
	// 	params.amountOutMinimum -= 1;

	// 	if (outputIsWETH) {
	// 		router.multicall{ value: value }(data);
	// 	} else {
	// 		router.exactInput{ value: value }(params);
	// 	}

	// 	vm.stopPrank();
	// }

	function mintNewPool(
		address token0,
		address token1,
		uint24 fee,
		uint160 currentPrice
	) internal {
		/* 创建池子 */
		nonfungiblePositionManager.createAndInitializePoolIfNecessary(
			token0,
			token1,
			fee,
			currentPrice
		);
	}

	function mintNewPositionByPrice(
		address token0,
		address token1,
		int24 tickSpacing,
		uint160 lowerPrice,
		uint160 upperPrice,
		uint256 amount0ToMint,
		uint256 amount1ToMint
	)
		internal
		returns (
			uint256 tokenId,
			uint128 liquidity,
			uint256 amount0,
			uint256 amount1
		)
	{
		// 转tick
		int24 tickLower = getTick(lowerPrice);
		int24 tickUpper = getTick(upperPrice);

		return
			providerLiquidity.mintNewPosition(
				tokens[1],
				tokens[2],
				tickSpacing,
				tickLower,
				tickUpper,
				amount0ToMint,
				amount1ToMint
			);
	}

	/* ExactInput */
}
