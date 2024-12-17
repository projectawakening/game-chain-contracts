// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { LocationData } from "../../codegen/index.sol";
import { DeployableSystemLib, deployableSystem } from "../../codegen/systems/DeployableSystemLib.sol";
import { InventorySystemLib, inventorySystem } from "../../codegen/systems/InventorySystemLib.sol";
import { EphemeralInventorySystemLib, ephemeralInventorySystem } from "../../codegen/systems/EphemeralInventorySystemLib.sol";
import { EntityRecordData } from "../entity-record/types.sol";
import { SmartObjectData } from "../deployable/types.sol";
import { WorldPosition } from "../location/types.sol";
import { SMART_STORAGE_UNIT } from "../constants.sol";
import { EveSystem } from "../EveSystem.sol";

contract SmartStorageUnitSystem is EveSystem {
  function createAndAnchorSmartStorageUnit(
    uint256 smartObjectId,
    EntityRecordData memory entityRecordData,
    SmartObjectData memory smartObjectData,
    WorldPosition memory worldPosition,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    uint256 storageCapacity,
    uint256 ephemeralStorageCapacity
  ) public {
    LocationData memory locationData = LocationData({
      solarSystemId: worldPosition.solarSystemId,
      x: worldPosition.position.x,
      y: worldPosition.position.y,
      z: worldPosition.position.z
    });

    DeployableSystemLib.createAndAnchorDeployable(
      deployableSystem,
      smartObjectId,
      SMART_STORAGE_UNIT,
      entityRecordData,
      smartObjectData,
      fuelUnitVolume,
      fuelConsumptionIntervalInSeconds,
      fuelMaxCapacity,
      locationData
    );

    InventorySystemLib.setInventoryCapacity(inventorySystem, smartObjectId, storageCapacity);

    EphemeralInventorySystemLib.setEphemeralInventoryCapacity(
      ephemeralInventorySystem,
      smartObjectId,
      ephemeralStorageCapacity
    );
  }
}
