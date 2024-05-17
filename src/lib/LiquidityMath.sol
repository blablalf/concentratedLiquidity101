// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.14;


import "./FixedPoint96.sol";
import "lib/prb-math/src/Common.sol";

library LiquidityMath {

    function addLiquidity(uint128 x, int128 y)
        internal
        pure
        returns (uint128 z)
    {
        if (y < 0) {
            z = x - uint128(-y);
        } else {
            z = x + uint128(y);
        }
    }
}