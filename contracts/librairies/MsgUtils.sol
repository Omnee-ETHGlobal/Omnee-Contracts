// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./MsgCodecs.sol";

library MsgUtils {
    struct StdMsg {
        uint8 messageType;
        bytes encodedContent;
    }

    struct BuyTokenMsg {
        address buyer;
        address tokenAddress;
        uint256 amount;
    }

    struct SellTokenMsg {
        address seller;
        address tokenAddress;
        uint256 amount;
    }

    function createBuyStdMessage(BuyTokenMsg memory message) internal pure returns (StdMsg memory) {
        return StdMsg({ messageType: MsgCodecs.MSG_BUY_REMOTE, encodedContent: abi.encode(message) });
    }

    function createSellStdMessage(SellTokenMsg memory message) internal pure returns (StdMsg memory) {
        return StdMsg({ messageType: MsgCodecs.MSG_SELL_REMOTE, encodedContent: abi.encode(message) });
    }

    function decodeStdMessage(StdMsg memory standardMessage) internal pure returns (bytes memory) {
        return standardMessage.encodedContent;
    }

    function addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}
