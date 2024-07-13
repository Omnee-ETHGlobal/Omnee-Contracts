// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library MessageTypes {
    struct BuyRemoteTokenMessage {
        address buyer;
        address tokenAddress;
        uint256 amount;
    }

    struct SellRemoteTokenMessage {
        address seller;
        address tokenAddress;
        uint256 amount;
    }
}
