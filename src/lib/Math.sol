// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./FixedPoint96.sol";
import "lib/prb-math/src/Common.sol";

library Math {

    // $\Delta x = (L << 96 -> Q96 format) * (\sqrt{P_target} - \sqrt{P_current}) / (\sqrt{P_target} * \sqrt{P_current})$
    // $\Delta x => Q96 format
    function calcAmount0DeltaRounding(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        require(sqrtPriceAX96 > 0);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtPriceBX96 - sqrtPriceAX96;

        if (roundUp) {
            amount0 = divRoundingUp(
                mulDivRoundingUp(numerator1, numerator2, sqrtPriceBX96),
                sqrtPriceAX96
            );
        } else {
            amount0 =
                mulDiv(numerator1, numerator2, sqrtPriceBX96) /
                sqrtPriceAX96;
        }
    }

    // $\Delta y = L * (\sqrt{P_target} - \sqrt{P_current}) / 2**96
    // $\Delta y => Q96 format
    function calcAmount1DeltaRounding(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        if (roundUp) {
            amount1 = mulDivRoundingUp(
                liquidity,
                (sqrtPriceBX96 - sqrtPriceAX96),
                FixedPoint96.Q96
            );
        } else {
            amount1 = mulDiv(
                liquidity,
                (sqrtPriceBX96 - sqrtPriceAX96),
                FixedPoint96.Q96
            );
        }
    }

    function calcAmount0Delta(
    uint160 sqrtPriceAX96,
    uint160 sqrtPriceBX96,
    int128 liquidity
    ) internal pure returns (int256 amount0) {
        amount0 = liquidity < 0
            ? -int256(
                calcAmount0DeltaRounding(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(-liquidity),
                    false
                )
            )
            : int256(
                calcAmount0DeltaRounding(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(liquidity),
                    true
                )
            );
    }

    function calcAmount1Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        amount1 = liquidity < 0
            ? -int256(
                calcAmount1DeltaRounding(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(-liquidity),
                    false
                )
            )
            : int256(
                calcAmount1DeltaRounding(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(liquidity),
                    true
                )
            );
    }

    function getNextSqrtPriceFromInput(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtPriceNextX96) {
        sqrtPriceNextX96 = zeroForOne
            ? getNextSqrtPriceFromAmount0RoundingUp(
                sqrtPriceX96,
                liquidity,
                amountIn
            )
            : getNextSqrtPriceFromAmount1RoundingDown(
                sqrtPriceX96,
                liquidity,
                amountIn
            );
    }

    // $\sqrt{P_target} = (L << 96 -> Q96 format) * \sqrt{P_current} / ((\Delta x * \sqrt{P_current}) + (L << 96 -> Q96 format))$
    // $\sqrt{P_target} = Q96 format
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {
        uint256 numerator = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 product = amountIn * sqrtPriceX96; //it can overflow

        if (product / amountIn == sqrtPriceX96) { // check no overflow
            uint256 denominator = numerator + product;
            if (denominator >= numerator) {
                return
                    uint160(
                        mulDivRoundingUp(numerator, sqrtPriceX96, denominator) //most precise formula
                    );
            }
        }
        // If overflow
        return
            uint160(
                divRoundingUp(numerator, (numerator / sqrtPriceX96) + amountIn)
            );
    }

    // $\sqrt{P_target} = \sqrt{P_current} + ((\Delta y << 96 -> Q96 format) / L)$
    // $\sqrt{P_target} = Q96 format
    // ((\Delta y << 96 -> Q96 format) / L) instead of ((\Delta y / L) << 96 -> Q96 format)
    // In order to not lose rounding
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {
        return
            sqrtPriceX96 +
            uint160((amountIn << FixedPoint96.RESOLUTION) / liquidity);
    }

    function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    function divRoundingUp(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            result := add(
                div(numerator, denominator),
                gt(mod(numerator, denominator), 0)
            )
        }
    }
}