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
		// 针对tokens[1],toekns[2]创建3个池子
		mintNewPool(tokens[1], tokens[2], FEE_LOW, INIT_PRICE);
		mintNewPool(tokens[1], tokens[2], FEE_MEDIUM, INIT_PRICE);
		mintNewPool(tokens[1], tokens[2], FEE_HIGH, INIT_PRICE);
		console2.log(uint256(INIT_PRICE));
		TransferHelper.safeApprove(
			tokens[1],
			address(providerLiquidity),
			type(uint256).max / 2
		);
		TransferHelper.safeApprove(
			tokens[2],
			address(providerLiquidity),
			type(uint256).max / 2
		);
		vm.stopPrank();
	}

	function test_mintNewPosition() public {
		vm.prank(deployer);
		providerLiquidity.mintNewPosition(
			tokens[1],
			tokens[2],
			TICK_LOW,
			getMinTick(TICK_LOW),
			getMaxTick(TICK_LOW),
			10000,
			10000
		);
	}

	function test_mintNewPosition_fail() public {}

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
		//         mintNewPosition(token0, token1, tickSpacing, tickLower, tickUpper, 1000000, 1000000);
	}

	/* ExactInput */
}
