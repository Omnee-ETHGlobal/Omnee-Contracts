// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

contract OmneeOFT is OFT {

    uint32 public eid;
    uint32 public base_eid = 40245;
    uint32[] public remote_eids = [40231, 40170];

    constructor(
        string memory _symbol,
        string memory _name,
        address _lzEndpoint,
        address _delegate,
        uint32 _eid
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        
        eid = _eid;

        for (uint256 i = 0; i < remote_eids.length; i++) {
            _setPeer(remote_eids[i], bytes32(uint256(uint160(address(this)))));
        }
    }

    function buyRemote() external payable {

    }

    function sellRemote() external {

    }

}
