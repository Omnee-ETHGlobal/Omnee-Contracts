// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OAppSender, OAppCore, MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract UniversalFactory is OAppSender {

    struct TokenInfo {
        address deployer;
        string name;
        string symbol;
        uint32[] eids;
        uint256 deployId;
    }

    uint256 public currentDeployId = 1;

    mapping(address => TokenInfo) public tokenByAddress;

    event OFTCreated(address, string, string, uint32[], uint256);

    constructor(address _endpoint, address _owner) OAppCore(_endpoint, _owner) Ownable(_owner) {}

    function _payNative(uint256 _nativeFee) internal override virtual returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    function deployOFT(
        string memory _name,
        string memory _symbol,
        uint32[] memory _eids,
        bytes memory _options
    ) external payable {

        uint256 totalNativeFee = quoteDeployOFT(_name, _symbol, _eids, _options);

        require(msg.value >= totalNativeFee, "Insufficient fee provided");

        uint256 totalNativeFeeUsed = 0;
        uint256 remainingValue = msg.value;
        
        for (uint256 i = 0; i < _eids.length; i++) {

            _getPeerOrRevert(_eids[i]);

            bytes memory payload = abi.encode(_name, _symbol, _eids[i], currentDeployId, msg.sender);

            MessagingFee memory fee = _quote(_eids[i], payload, _options, false);

            totalNativeFeeUsed += fee.nativeFee;
            remainingValue -= fee.nativeFee;

            require(remainingValue >= 0, "Insufficient fee for this destination");

            _lzSend(_eids[i], payload, _options, fee, payable(msg.sender));
        }

        /// TODO: Call BASE Factory to deploy the OFT on main chain

        currentDeployId++;

        /// TODO: Put token address instead of msg.sender

        tokenByAddress[msg.sender] = TokenInfo(msg.sender, _name, _symbol, _eids, currentDeployId);

        emit OFTCreated(msg.sender, _name, _symbol, _eids, currentDeployId);
    }

    function quoteDeployOFT(string memory _name, string memory _symbol, uint32[] memory _eids, bytes memory _options) public view returns (uint256) {

        uint256 nativeFee = 0;

        for (uint256 i = 0; i < _eids.length; i++) {
            _getPeerOrRevert(_eids[i]);

            bytes memory payload = abi.encode(_name, _symbol, _eids[i], currentDeployId, msg.sender);

            MessagingFee memory fee = _quote(_eids[i], payload, _options, false);

            nativeFee += fee.nativeFee;
        }
        return nativeFee;
    }
}
