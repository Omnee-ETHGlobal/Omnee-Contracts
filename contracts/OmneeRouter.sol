// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IOFT, SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol"; 

contract OmneeRouter is OApp {

    uint32 public eid;
    uint32 public BASE_EID = 40245;

    bytes32 public bondingCurve;

    constructor(address _endpoint, address _delegate, uint32 _eid) OApp(_endpoint, _delegate) Ownable(_delegate) {
        eid = _eid;
    }

    function buyRemote(
        address tokenAddress,
        bytes calldata _options
    ) external payable returns (MessagingReceipt memory receipt) {

        uint8 BUY_MESSAGE = 1;

        MessagingFee memory fee = _quote(BASE_EID, abi.encode(BUY_MESSAGE, tokenAddress, msg.sender, eid, msg.value), _options, false);

        require(msg.value >= fee.nativeFee, "Insufficient fee provided");

        bytes memory _payload = abi.encode(
            BUY_MESSAGE,
            tokenAddress, ///  the OFT to brought
            msg.sender, /// final destination address for OFT
            eid, /// destination chain for OFT
            msg.value - fee.nativeFee /// amount of ETH, minus the fee for the swap
        );

        receipt = _lzSend(BASE_EID, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    function sellRemote(uint256 amount, address tokenAddr, bytes calldata _options) public payable {

        
        uint8 SELL_MESSAGE = 2;

        bytes memory payload = abi.encode(
            SELL_MESSAGE,
            tokenAddr, ///  the OFT to brought
            msg.sender, /// final destination address for OFT
            eid, /// destination chain for OFT
            amount /// amount of OFT to sell
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

    function lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) public payable override {}

    function quote(
        address tokenAddress,
        bytes memory _options,
        uint256 amount
    ) public view returns (uint256) {

        uint8 BUY_MESSAGE = 1;

        MessagingFee memory fee = _quote(BASE_EID, abi.encode(BUY_MESSAGE, tokenAddress, msg.sender, eid, amount), _options, false);

        return fee.nativeFee;
    }

    function addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }

    function setBondingCurve(bytes32 _bondingCurve) public onlyOwner {
        bondingCurve = _bondingCurve;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _payload,
        address _executor,
        bytes calldata _extraData
    ) internal override { }
}
