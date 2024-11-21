// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { EveSystem } from "../EveSystem.sol";
import { InventorySystem } from "../inventory/InventorySystem.sol";
import { EphemeralInventorySystem } from "../inventory/EphemeralInventorySystem.sol";
import { DeployableSystem } from "../deployable/DeployableSystem.sol";
import { DeployableUtils } from "../deployable/DeployableUtils.sol";
import { InventoryUtils } from "../inventory/InventoryUtils.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { InventoryItem, TransferItem } from "../inventory/types.sol";
import { DeployableSystem } from "../deployable/DeployableSystem.sol";
import { State, SmartObjectData } from "../deployable/types.sol";
import { WorldPosition } from "../location/types.sol";
import { CRUDE_LIFT } from "../constants.sol";
import { EntityRecordData, CrudeLift, CrudeLiftData, LocationData, Lens, DeployableToken } from "../../codegen/index.sol";

uint256 constant CRUDE_MATTER = 1;
uint256 constant LENS = 2;

contract CrudeLiftSystem is EveSystem {
  using WorldResourceIdLib for ResourceId;

  ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
  ResourceId inventorySystemId = InventoryUtils.inventorySystemId();
  ResourceId ephemeralInventorySystemId = InventoryUtils.ephemeralInventorySystemId();

  error LensNotInserted();
  error LensExhausted();
  error LensAlreadyInserted();
  error CannotRemoveLensWhileMining();
  error AlreadyMining();
  error NotMining();

  function createAndAnchorCrudeLift(
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
    world().call(
      deployableSystemId,
      abi.encodeCall(
        DeployableSystem.createAndAnchorDeployable,
        (
          smartObjectId,
          CRUDE_LIFT,
          entityRecordData,
          smartObjectData,
          fuelUnitVolume,
          fuelConsumptionIntervalInSeconds,
          fuelMaxCapacity,
          locationData
        )
      )
    );

    world().call(
      inventorySystemId,
      abi.encodeCall(InventorySystem.setInventoryCapacity, (smartObjectId, storageCapacity))
    );

    world().call(
      ephemeralInventorySystemId,
      abi.encodeCall(EphemeralInventorySystem.setEphemeralInventoryCapacity, (smartObjectId, ephemeralStorageCapacity))
    );
  }

  function insertLens(uint256 smartObjectId) public {
    if (CrudeLift.getLensId(smartObjectId) != 0) revert LensAlreadyInserted();
    if (Lens.getExhausted(lensId)) revert LensExhausted();

    // get lens from ephemeral inventory
    TransferItem[] memory items = new TransferItem[](1);
    items[0] = TransferItem({ inventoryItemId: lensId, owner: getOwner(smartObjectId), quantity: 1 });
    _world().call(
      ephemeralInventorySystemId,
      abi.encodeCall(EphemeralInventorySystem.ephemeralToInventoryTransfer, (smartObjectId, items))
    );

    // If durability is 0 but not exhausted, it means the lens has not been initialized onchain yet
    if (Lens.getDurability(lensId) == 0) {
      // TODO decide on a default durability. Maybe store this somewhere else
      Lens.setDurability(lensId, 100);
    }

    CrudeLift.setLensId(smartObjectId, lensId);
  }

  function startMining(uint256 smartObjectId) public {
    CrudeLiftData memory lift = CrudeLift.get(smartObjectId);

    if (!lift.lensInserted) revert LensNotInserted();
    if (lift.startMiningTime != 0) revert AlreadyMining();

    CrudeLift.setStartMiningTime(smartObjectId, block.timestamp);
  }

  function stopMining(uint256 smartObjectId) public {
    CrudeLiftData memory lift = CrudeLift.get(smartObjectId);
    if (lift.startMiningTime == 0) revert NotMining();

    uint256 remainingLensDurability = Lens.getDurability(CrudeLift.getLensId(smartObjectId));
    uint256 miningDuration = block.timestamp - lift.startMiningTime;

    // the lens was exhaused at some point during mining
    if (miningDuration >= remainingLensDurability) {
      miningDuration = remainingLensDurability;
      Lens.setExhausted(CrudeLift.getLensId(smartObjectId), true);
      Lens.setDurability(CrudeLift.getLensId(smartObjectId), 0);
    } else {
      Lens.setDurability(CrudeLift.getLensId(smartObjectId), remainingLensDurability - miningDuration);
    }

    uint256 crudeMined = calculateCrudeMined(miningDuration);

    // Reset mining state
    CrudeLift.setStartMiningTime(smartObjectId, 0);

    InventoryItem[] memory items = new InventoryItem[](1);
    address owner = getOwner(smartObjectId);
    // TODO: no idea how to fill this out
    items[0] = InventoryItem({
      owner: owner,
      typeId: CRUDE_MATTER,
      itemId: 1,
      volume: crudeMined,
      quantity: crudeMined
    });
    _world().call(inventorySystemId, abi.encodeCall(InventorySystem.depositToInventory, (smartObjectId, items)));
  }

  function removeLens(uint256 smartObjectId) public {
    if (CrudeLift.getLensId(smartObjectId) == 0) revert LensNotInserted();
    if (CrudeLift.getStartMiningTime(smartObjectId) != 0) revert CannotRemoveLensWhileMining();

    CrudeLift.setLensId(smartObjectId, 0);

    TransferItem[] memory items = new TransferItem[](1);
    items[0] = TransferItem({ inventoryItemId: CrudeLift.getLensId(smartObjectId), quantity: 1 });
    _world().call(
      ephemeralInventorySystemId,
      abi.encodeCall(
        EphemeralInventorySystem.inventoryToEphemeralTransfer,
        (smartObjectId, getOwner(smartObjectId), items)
      )
    );
  }

  function getOwner(uint256 smartObjectId) public view returns (address) {
    address erc721Address = DeployableToken.getErc721Address();
    return IERC721(erc721Address).ownerOf(smartObjectId);
  }

  function calculateCrudeMined(uint256 duration) internal pure returns (uint256) {
    // Implement the logic to calculate crude mined based on duration
    return duration * 10; // Example calculation
  }
}
