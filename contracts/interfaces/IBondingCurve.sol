// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IBondingCurve {
    function addToken(address _tokenAddress) external;
}