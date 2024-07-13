// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import { MessagingReceipt, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

import "./librairies/MsgUtils.sol";

contract OmneeOFT is OFT {
    uint32 public eid;
    address public bondingCurve = address(0);

    uint32 public BASE_EID = 40245;
    uint32[] public REMOTE_EIDS = [40231, 40170];

    constructor(
        string memory _symbol,
        string memory _name,
        address _lzEndpoint,
        address _delegate,
        uint32 _eid
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        eid = _eid;

        for (uint256 i = 0; i < REMOTE_EIDS.length; i++) {
            _setPeer(REMOTE_EIDS[i], MsgUtils.addressToBytes32(address(this)));
        }
    }

    function buyRemote(uint256 _amount) external payable {
        MsgUtils.BuyTokenMsg memory message = MsgUtils.BuyTokenMsg({
            buyer: msg.sender,
            tokenAddress: address(this),
            amount: _amount
        });

        bytes memory options = OptionsBuilder.newOptions().addExecutorNativeDropOption(
            msg.value,
            MsgUtils.addressToBytes32(bondingCurve)
        );

        MessagingReceipt memory receipt = _lzSend(
            BASE_EID,
            MsgUtils.createBuyStdMessage(message),
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    function sellRemote() external {}
}
