// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

/**
 * @title IModuleSystem
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 * Needs to match corresponding System exhaustively
 */
interface IModuleSystem {
  function registerEVEModule(uint256 moduleId, bytes16 moduleName, ResourceId systemId) external;

  function registerEVEModules(uint256 moduleId, bytes16 moduleName, ResourceId[] memory systemIds) external;

  function associateModule(uint256 entityId, uint256 moduleId) external;

  function associateModules(uint256 entityId, uint256[] memory moduleIds) external;

  function removeEntityModuleAssociation(uint256 entityId, uint256 moduleId) external;

  function removeSystemModuleAssociation(ResourceId systemId, uint256 moduleId) external;
}
