// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IOFT, SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

/// @title OmneeRouter
/// @notice A cross-chain router for buying and selling tokens using LayerZero
contract OmneeRouter is OApp {
    /// @notice The Endpoint ID of the current chain
    uint32 public eid;

    /// @notice The Base Endpoint ID (assumed to be the chain where the bonding curve is deployed)
    uint32 public constant BASE_EID = 40245;

    /// @notice The address of the bonding curve contract (in bytes32 format)
    bytes32 public bondingCurve;

    /// @notice Initializes the contract
    /// @param _endpoint The LayerZero endpoint address
    /// @param _delegate The address to be set as the owner
    /// @param _eid The Endpoint ID of the current chain
    constructor(address _endpoint, address _delegate, uint32 _eid) OApp(_endpoint, _delegate) Ownable(_delegate) {
        eid = _eid;
    }

    /// @notice Initiates a remote token purchase
    /// @param tokenAddress The address of the token to buy
    /// @param _options Additional options for the LayerZero message
    /// @return receipt The receipt of the LayerZero message
    function buyRemote(
        address tokenAddress,
        bytes calldata _options
    ) external payable returns (MessagingReceipt memory receipt) {
        uint8 BUY_MESSAGE = 1;

        MessagingFee memory fee = _quote(
            BASE_EID,
            abi.encode(BUY_MESSAGE, tokenAddress, msg.sender, eid, msg.value),
            _options,
            false
        );

        require(msg.value >= fee.nativeFee, "Insufficient fee provided");

        bytes memory _payload = abi.encode(
            BUY_MESSAGE,
            tokenAddress, // the OFT to be bought
            msg.sender, // final destination address for OFT
            eid, // destination chain for OFT
            msg.value - fee.nativeFee // amount of ETH, minus the fee for the swap
        );

        receipt = _lzSend(BASE_EID, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    /// @notice Initiates a remote token sale
    /// @param amount The amount of tokens to sell
    /// @param tokenAddr The address of the token to sell
    /// @param _options Additional options for the LayerZero message
    function sellRemote(uint256 amount, address tokenAddr, bytes calldata _options) public payable {
        uint8 SELL_MESSAGE = 2;

        bytes memory payload = abi.encode(
            SELL_MESSAGE,
            tokenAddr, // the OFT to be sold
            msg.sender, // final destination address for ETH
            eid, // destination chain for ETH
            amount // amount of OFT to sell
        );

        SendParam memory sendParam = SendParam({
            dstEid: BASE_EID,
            to: bondingCurve,
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: _options,
            composeMsg: payload,
            oftCmd: bytes("")
        });

        MessagingFee memory fee = IOFT(tokenAddr).quoteSend(sendParam, false);

        require(msg.value >= fee.nativeFee, "Insufficient fee provided");

        IERC20(tokenAddr).transferFrom(msg.sender, address(this), amount);
        IOFT(tokenAddr).send(sendParam, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    /// @notice Handles incoming LayerZero messages (placeholder implementation)
    function lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) public payable override {}

    /// @notice Quotes the fee for a remote token purchase
    /// @param tokenAddress The address of the token to buy
    /// @param _options Additional options for the LayerZero message
    /// @param amount The amount of ETH to spend
    /// @return The quoted fee in native currency
    function quote(address tokenAddress, bytes memory _options, uint256 amount) public view returns (uint256) {
        uint8 BUY_MESSAGE = 1;

        MessagingFee memory fee = _quote(
            BASE_EID,
            abi.encode(BUY_MESSAGE, tokenAddress, msg.sender, eid, amount),
            _options,
            false
        );

        return fee.nativeFee;
    }

    /// @notice Converts an address to bytes32
    /// @param _address The address to convert
    /// @return The bytes32 representation of the address
    function addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    /// @notice Converts bytes32 to an address
    /// @param _bytes32 The bytes32 to convert
    /// @return The address representation of the bytes32
    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }

    /// @notice Sets the address of the bonding curve contract
    /// @param _bondingCurve The address of the bonding curve contract (in bytes32 format)
    function setBondingCurve(bytes32 _bondingCurve) public onlyOwner {
        bondingCurve = _bondingCurve;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _payload,
        address _executor,
        bytes calldata _extraData
    ) internal override {}
}
