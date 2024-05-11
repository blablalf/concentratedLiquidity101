// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library Position {
    struct Info {
        uint128 liquidity;
    }

    /*
    From https://docs.soliditylang.org/en/latest/style-guide.html#function-argument-names
    When writing library functions that operate on a custom struct, the struct should be the first argument and should always be named self.
    */
    function update(Info storage self, uint128 liquidityDelta) internal {
        uint128 liquidityBefore = self.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;

        self.liquidity = liquidityAfter;
    }

    /*
    From https://docs.soliditylang.org/en/latest/style-guide.html#function-argument-names
    When writing library functions that operate on a custom struct, the struct should be the first argument and should always be named self.
    */
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 lowerTick,
        int24 upperTick
    ) internal view returns (Position.Info storage position) {
        position = self[
            keccak256(abi.encodePacked(owner, lowerTick, upperTick))
        ];
    }
}