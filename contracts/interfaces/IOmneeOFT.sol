// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IOFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { IOAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";

interface IOmneeOFT is IOFT, IOAppCore {
    function buyRemote(bytes memory _options) external payable;
    function sellRemote(uint256 _amount, bytes memory _options) external payable;
}
