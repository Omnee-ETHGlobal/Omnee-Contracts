// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OAppReceiver, Origin, OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Create3 } from "./libs/Create3.sol";
import { OmneeOFT } from "./OmneeOFT.sol";

contract OFTFactory is OAppReceiver {
    uint32 public eid;
    bytes32 public universalFactory;

    constructor(
        address _endpoint,
        address _owner,
        uint32 _eid,
        bytes32 _universalFactory
    ) OAppCore(_endpoint, _owner) Ownable(_owner) {
        eid = _eid;
        universalFactory = _universalFactory;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        // TODO: receive the payload from the UniversalFactory and deploy the OmneeOFT 

        (string memory _name, 
        string memory _symbol, 
        uint32 _eid, 
        uint256 _deployId, 
        address _deployer) = abi.decode(payload, (string, string, uint32, uint256, address));

    }
}
