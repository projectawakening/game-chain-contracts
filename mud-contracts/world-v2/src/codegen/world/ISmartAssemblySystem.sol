// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityRecordData } from "../../namespaces/evefrontier/systems/entity-record/types.sol";

/**
 * @title ISmartAssemblySystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ISmartAssemblySystem {
  error SmartAssemblyTypeAlreadyExists(uint256 smartObjectId);
  error SmartAssemblyTypeCannotBeEmpty(uint256 smartObjectId);
  error SmartAssemblyDoesNotExist(uint256 smartObjectId);

  function evefrontier__createSmartAssembly(
    uint256 smartObjectId,
    string memory smartAssemblyType,
    EntityRecordData memory entityRecord
  ) external;

  function evefrontier__setSmartAssemblyType(uint256 smartObjectId, string memory smartAssemblyType) external;

  function evefrontier__updateSmartAssemblyType(uint256 smartObjectId, string memory smartAssemblyType) external;
}
