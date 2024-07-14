// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import { MessagingReceipt, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

import "./librairies/MsgUtils.sol";

/**
 * @title OmneeOFT
 * @dev A cross-chain token contract using LayerZero's OFT (Omnichain Fungible Token) standard
 */
contract OmneeOFT is OFT {
    // State variables
    uint32 public eid;
    address public bondingCurve;

    // Constants
    uint32 public constant BASE_EID = 40245;
    uint32[] public REMOTE_EIDS = [40231, 40170, 40232];

    /**
     * @dev Constructor to initialize the OmneeOFT contract
     * @param _symbol The token symbol
     * @param _name The token name
     * @param _lzEndpoint The LayerZero endpoint address
     * @param _delegate The delegate address for ownership
     * @param _eid The endpoint ID for this chain
     * @param _bondingCurve The address of the bonding curve contract
     */
    constructor(
        string memory _symbol,
        string memory _name,
        address _lzEndpoint,
        address _delegate,
        uint32 _eid,
        address _bondingCurve
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        eid = _eid;
        bondingCurve = _bondingCurve;

        // Set up peers for cross-chain communication
        for (uint256 i = 0; i < REMOTE_EIDS.length; i++) {
            if (REMOTE_EIDS[i] != eid) {
                _setPeer(REMOTE_EIDS[i], MsgUtils.addressToBytes32(address(this)));
            }
        }

        // Mint initial supply if this is the base chain
        if (_eid == BASE_EID) {
            _mint(bondingCurve, 100_000_000 * 1e18);
        }
    }

    /**
     * @dev Allows users to buy tokens remotely from the base chain
     * @param _options Additional options for the LayerZero message
     */
    function buyRemote(bytes memory _options) external payable {
        MsgUtils.BuyTokenMsg memory message = MsgUtils.BuyTokenMsg({
            buyer: msg.sender,
            tokenAddress: address(this),
            amount: msg.value
        });

        // Quote the fee for the LayerZero message
        MessagingFee memory fee = _quote(BASE_EID, abi.encode(MsgUtils.createBuyStdMessage(message)), _options, false);

        require(msg.value >= fee.nativeFee, "Insufficient fee provided");

        // Send the LayerZero message to initiate the buy
        _lzSend(
            BASE_EID,
            abi.encode(MsgUtils.createBuyStdMessage(message)),
            _options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    /**
     * @dev Allows users to sell tokens remotely to the base chain
     * @param _amount The amount of tokens to sell
     * @param _options Additional options for the LayerZero message
     */
    function sellRemote(uint256 _amount, bytes memory _options) external payable {
        MsgUtils.SellTokenMsg memory message = MsgUtils.SellTokenMsg({
            seller: msg.sender,
            tokenAddress: address(this),
            amount: _amount
        });

        // Quote the fee for the LayerZero message
        MessagingFee memory fee = _quote(BASE_EID, abi.encode(MsgUtils.createSellStdMessage(message)), _options, false);

        require(fee.nativeFee <= msg.value, "Insufficient fee provided");

        // Debit the tokens from the sender
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(msg.sender, _amount, _amount, BASE_EID);

        // Send the LayerZero message to initiate the sell
        MessagingReceipt memory receipt = _lzSend(
            BASE_EID,
            abi.encode(MsgUtils.createSellStdMessage(message)),
            _options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }
}
