// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OAppReceiver, Origin, OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Create3 } from "./librairies/Create3.sol";
import { OmneeOFT } from "./OmneeOFT.sol";

contract OFTFactory is OAppReceiver {
    uint32 public eid;
    bytes32 public universalFactory;
    string public salt = "OMNEE_OFT";

    uint32 public baseEID = 40245;

    mapping(uint256 => address) public deployIdToAddress;

    address public bondingCurve; /// Passed to the OFT for initial mint

    event OFTCreated(address indexed sender, string indexed name, string symbol, uint32 eid, uint256 deployId);

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
        bytes32,
        bytes calldata payload,
        address,
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        require(_origin.sender == universalFactory, "Unauthorized");

        (string memory _name, string memory _symbol, uint32 _eid, uint256 _deployId, address _deployer) = abi.decode(
            payload,
            (string, string, uint32, uint256, address)
        );

        bytes memory bytecode = type(OmneeOFT).creationCode;
        bytes32 _salt = keccak256(abi.encodePacked(salt, _deployId));

        address oftAddr = Create3.create3(
            _salt,
            abi.encodePacked(bytecode, abi.encode(_symbol, _name, endpoint, _deployer, _eid, bondingCurve))
        );

        deployIdToAddress[_deployId] = oftAddr;

        emit OFTCreated(oftAddr, _name, _symbol, _eid, _deployId);
    }

    function deployOFTBase(
        string memory _name,
        string memory _symbol,
        uint256 _deployId,
        address admin
    ) external returns (address) {
        require(bytes32(uint256(uint160(msg.sender))) == universalFactory, "OFTFactory: FORBIDDEN");

        bytes memory bytecode = type(OmneeOFT).creationCode;
        bytes32 _salt = keccak256(abi.encodePacked(salt, _deployId));

        address oftAddr = Create3.create3(
            _salt,
            abi.encodePacked(bytecode, abi.encode(_symbol, _name, endpoint, admin, baseEID, bondingCurve))
        );

        emit OFTCreated(oftAddr, _name, _symbol, baseEID, _deployId);

        return oftAddr;
    }

    function setBondingCurve(address _bondingCurve) public onlyOwner {
        bondingCurve = _bondingCurve;
    }
}
