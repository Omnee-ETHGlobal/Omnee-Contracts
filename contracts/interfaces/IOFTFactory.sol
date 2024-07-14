// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IOFTFactory {
    function deployOFTBase(string memory _name, string memory _symbol, uint256 _deployId, address admin) external returns (address);
}