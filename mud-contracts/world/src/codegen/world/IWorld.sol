// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { IAccess } from "./IAccess.sol";
import { IEntityRecord } from "./IEntityRecord.sol";
import { IEphemeralInventory } from "./IEphemeralInventory.sol";
import { IInventory } from "./IInventory.sol";
import { IInventoryInteract } from "./IInventoryInteract.sol";
import { ILocationSystem } from "./ILocationSystem.sol";
import { ISmartCharacter } from "./ISmartCharacter.sol";
import { ISmartDeployable } from "./ISmartDeployable.sol";
import { ISmartStorageUnit } from "./ISmartStorageUnit.sol";
import { IStaticData } from "./IStaticData.sol";

/**
 * @title IWorld
 * @notice This interface integrates all systems and associated function selectors
 * that are dynamically registered in the World during deployment.
 * @dev This is an autogenerated file; do not edit manually.
 */
interface IWorld is
  IBaseWorld,
  IAccess,
  IEntityRecord,
  IEphemeralInventory,
  IInventory,
  IInventoryInteract,
  ILocationSystem,
  ISmartCharacter,
  ISmartDeployable,
  ISmartStorageUnit,
  IStaticData
{

}
