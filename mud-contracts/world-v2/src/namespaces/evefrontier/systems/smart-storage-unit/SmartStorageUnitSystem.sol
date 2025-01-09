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
import { CreateAndAnchorDeployableParams } from "../deployable/types.sol";

contract SmartStorageUnitSystem is EveSystem {
  function createAndAnchorSmartStorageUnit(
    CreateAndAnchorDeployableParams memory params,
    uint256 storageCapacity,
    uint256 ephemeralStorageCapacity
  ) public {
    params.smartAssemblyType = SMART_STORAGE_UNIT;
    deployableSystem.createAndAnchorDeployable(params);

    inventorySystem.setInventoryCapacity(params.smartObjectId, storageCapacity);

    ephemeralInventorySystem.setEphemeralInventoryCapacity(params.smartObjectId, ephemeralStorageCapacity);
  }
}
