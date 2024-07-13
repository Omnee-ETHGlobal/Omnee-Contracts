// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import { MessagingReceipt, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

import "./librairies/MsgUtils.sol";

contract OmneeOFT is OFT {
    uint32 public eid;
    address public bondingCurve = 0x000000000000000000000000000000000000dEaD; 

    uint32 public BASE_EID = 40245;
    uint32[] public REMOTE_EIDS = [40231, 40170, 40232];

    constructor(
        string memory _symbol,
        string memory _name,
        address _lzEndpoint,
        address _delegate,
        uint32 _eid
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        eid = _eid;

        for (uint256 i = 0; i < REMOTE_EIDS.length; i++) {
            if (REMOTE_EIDS[i] != eid) {
                _setPeer(REMOTE_EIDS[i], MsgUtils.addressToBytes32(address(this)));
            }   
        }
        if (_eid == BASE_EID) {
            _mint(bondingCurve, 100_000_000 * 1e18);
        }
        
    }

    function buyRemote(bytes memory _options) external payable {

        MsgUtils.BuyTokenMsg memory message = MsgUtils.BuyTokenMsg({
            buyer: msg.sender,
            tokenAddress: address(this),
            amount: msg.value
        });

        MessagingFee memory fee = _quote(BASE_EID, abi.encode(MsgUtils.createBuyStdMessage(message)), _options, false);

        require(msg.value >= fee.nativeFee, "Insufficient fee provided");

        MessagingReceipt memory receipt = _lzSend(
            BASE_EID,
            abi.encode(MsgUtils.createBuyStdMessage(message)),
            _options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    function sellRemote(uint256 _amount, bytes memory _options) external payable {
        MsgUtils.SellTokenMsg memory message = MsgUtils.SellTokenMsg({
            seller: msg.sender,
            tokenAddress: address(this),
            amount: _amount
        });

        MessagingFee memory fee = _quote(BASE_EID, abi.encode(MsgUtils.createSellStdMessage(message)), _options, false);

        require(fee.nativeFee <= msg.value, "Insufficient fee provided");

        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(msg.sender, _amount, _amount, BASE_EID);

        MessagingReceipt memory receipt = _lzSend(
            BASE_EID,
            abi.encode(MsgUtils.createSellStdMessage(message)),
            _options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    
    }
}
