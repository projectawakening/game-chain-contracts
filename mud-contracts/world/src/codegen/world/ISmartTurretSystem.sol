// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityRecordData, WorldPosition } from "../../modules/smart-storage-unit/types.sol";
import { SmartObjectData } from "../../modules/smart-deployable/types.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { TargetPriority, Turret, SmartTurretTarget } from "../../modules/smart-turret/types.sol";

/**
 * @title ISmartTurretSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ISmartTurretSystem {
  error SmartTurret_UndefinedClassId();
  error SmartTurret_NotConfigured(uint256 smartObjectId);

  function eveworld__createAndAnchorSmartTurret(
    uint256 smartObjectId,
    EntityRecordData memory entityRecordData,
    SmartObjectData memory smartObjectData,
    WorldPosition memory worldPosition,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity
  ) external;

  function eveworld__configureSmartTurret(uint256 smartObjectId, ResourceId systemId) external;

  function eveworld__inProximity(
    uint256 smartObjectId,
    uint256 turretOwnerCharacterId,
    TargetPriority[] memory priorityQueue,
    Turret memory turret,
    SmartTurretTarget memory turretTarget
  ) external returns (TargetPriority[] memory updatedPriorityQueue);

  function eveworld__aggression(
    uint256 smartObjectId,
    uint256 turretOwnerCharacterId,
    TargetPriority[] memory priorityQueue,
    Turret memory turret,
    SmartTurretTarget memory aggressor,
    SmartTurretTarget memory victim
  ) external returns (TargetPriority[] memory updatedPriorityQueue);
}
