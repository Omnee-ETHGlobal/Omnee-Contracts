// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OAppReceiver, Origin, OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Create3 } from "./librairies/Create3.sol";
import { OmneeOFT } from "./OmneeOFT.sol";

/// @title OFTFactory
/// @notice Factory contract for deploying OmneeOFT tokens across different chains
/// @dev Uses LayerZero for cross-chain communication and Create3 for deterministic deployments
contract OFTFactory is OAppReceiver {
    // State variables
    uint32 public eid;
    bytes32 public universalFactory;
    string public salt = "OMNEE_OFT";
    uint32 public baseEID = 40245;
    address public bondingCurve; /// Address passed to the OFT for initial mint

    // Mappings
    mapping(uint256 => address) public deployIdToAddress;

    // Events
    event OFTCreated(address indexed sender, string indexed name, string symbol, uint32 eid, uint256 deployId);

    /// @notice Constructor to initialize the OFTFactory
    /// @param _endpoint Address of the LayerZero endpoint
    /// @param _owner Address of the contract owner
    /// @param _eid Endpoint ID for this chain
    /// @param _universalFactory Address of the universal factory
    constructor(
        address _endpoint,
        address _owner,
        uint32 _eid,
        bytes32 _universalFactory
    ) OAppCore(_endpoint, _owner) Ownable(_owner) {
        eid = _eid;
        universalFactory = _universalFactory;
    }

    /// @notice Handles incoming LayerZero messages to deploy OFTs
    /// @dev Only allows messages from the universal factory
    /// @param _origin Origin information of the LayerZero message
    /// @param payload Encoded deployment information
    function _lzReceive(
        Origin calldata _origin,
        bytes32,
        bytes calldata payload,
        address,
        bytes calldata
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

    /// @notice Deploys an OFT on the Base chain
    /// @dev Can only be called by the universal factory
    /// @param _name Name of the OFT
    /// @param _symbol Symbol of the OFT
    /// @param _deployId Unique deployment ID
    /// @param admin Address of the OFT admin
    /// @return Address of the deployed OFT
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

    /// @notice Sets the address of the bonding curve contract
    /// @dev Can only be called by the contract owner
    /// @param _bondingCurve Address of the new bonding curve contract
    function setBondingCurve(address _bondingCurve) public onlyOwner {
        bondingCurve = _bondingCurve;
    }
}
