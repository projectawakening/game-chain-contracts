// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { EveSystem } from "../EveSystem.sol";
import { InventorySystem } from "../inventory/InventorySystem.sol";
import { EphemeralInventorySystem } from "../inventory/EphemeralInventorySystem.sol";
import { InventoryInteractSystem } from "../inventory/InventoryInteractSystem.sol";
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
import { EntityRecordData } from "../entity-record/types.sol";
import { CrudeLift, CrudeLiftData, LocationData, Lens, DeployableToken, Rift, InventoryItem as InventoryItemTable, Inventory, EntityRecord } from "../../codegen/index.sol";

uint256 constant CRUDE_MATTER = 1;
uint256 constant LENS = 2;
uint256 constant LENS_EXPIRY_TIME = 90 days;

contract CrudeLiftSystem is EveSystem {
  using WorldResourceIdLib for ResourceId;

  ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
  ResourceId inventorySystemId = InventoryUtils.inventorySystemId();
  ResourceId ephemeralInventorySystemId = InventoryUtils.ephemeralInventorySystemId();
  ResourceId inventoryInteractSystemId = InventoryUtils.inventoryInteractSystemId();

  error LensNotInserted();
  error LensExhausted();
  error LensAlreadyInserted();
  error LensExpired();
  error CannotRemoveLensWhileMining();
  error AlreadyMining();
  error NotMining();
  error RiftNotFoundOrDepleted();
  error InvalidMiningRate(uint256 miningRate);
  error InsufficientCrude();
  error RiftCollapsed();

  modifier onlyServer() {
    // TODO: Implement
    _;
  }

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
  ) public onlyServer {
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

  function insertLens(uint256 smartObjectId, address player) public onlyServer {
    if (CrudeLift.getLensId(smartObjectId) != 0) revert LensAlreadyInserted();

    uint256[] memory items = Inventory.getItems(smartObjectId);
    uint256 foundLensId = 0;
    for (uint256 i = 0; i < items.length; i++) {
      // how do i do this?
      if (EntityRecord.getTypeId(items[i]) == LENS) {
        foundLensId = items[i];
        break;
      }
    }
    if (foundLensId == 0) revert LensNotInserted();
    if (Lens.getExhausted(foundLensId)) revert LensExhausted();
    if (Lens.getCreatedAt(foundLensId) + LENS_EXPIRY_TIME < block.timestamp) revert LensExpired();

    // get lens from ephemeral inventory
    TransferItem[] memory transferItems = new TransferItem[](1);
    transferItems[0] = TransferItem({ inventoryItemId: foundLensId, owner: player, quantity: 1 });
    world().call(
      inventoryInteractSystemId,
      abi.encodeCall(InventoryInteractSystem.ephemeralToInventoryTransfer, (smartObjectId, player, transferItems))
    );

    // If durability is 0 but not exhausted, it means the lens has not been initialized onchain yet
    if (Lens.getDurability(foundLensId) == 0) {
      // TODO durability needs to get set when a Lens is crafted
      Lens.setDurability(foundLensId, 100);
    }

    CrudeLift.setLensId(smartObjectId, foundLensId);
  }

  function startMining(uint256 smartObjectId, uint256 riftId, uint256 miningRate) public onlyServer {
    CrudeLiftData memory lift = CrudeLift.get(smartObjectId);

    if (miningRate < 1_000 || miningRate > 200_000) revert InvalidMiningRate(miningRate);
    if (lift.lensId == 0) revert LensNotInserted();
    if (lift.startMiningTime != 0) revert AlreadyMining();
    if (getCrudeAmount(riftId) == 0) revert RiftNotFoundOrDepleted();
    if (Rift.getMiningCrudeLiftId(riftId) != 0) revert AlreadyMining();
    if (Rift.getCollapsedAt(riftId) != 0) revert RiftCollapsed();

    CrudeLift.setStartMiningTime(smartObjectId, block.timestamp);
    CrudeLift.setMiningRiftId(smartObjectId, riftId);
    CrudeLift.setMiningRate(smartObjectId, miningRate);
    Rift.setMiningCrudeLiftId(riftId, smartObjectId);
  }

  function stopMining(uint256 smartObjectId) public onlyServer {
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

    uint256 riftId = CrudeLift.getMiningRiftId(smartObjectId);
    if (Rift.getCollapsedAt(riftId) != 0) revert RiftCollapsed();

    uint256 crudeMined = calculateCrudeMined(CrudeLift.getMiningRate(smartObjectId), miningDuration);

    uint256 remainingCrudeAmount = getCrudeAmount(riftId);
    if (crudeMined > remainingCrudeAmount) {
      crudeMined = remainingCrudeAmount;
    }
    removeCrude(riftId, crudeMined);
    addCrude(smartObjectId, crudeMined);

    // Reset mining state
    CrudeLift.setStartMiningTime(smartObjectId, 0);
    CrudeLift.setMiningRiftId(smartObjectId, 0);

    Rift.setMiningCrudeLiftId(riftId, 0);
  }

  function retrieveCrude(uint256 smartObjectId, uint256 shipId, uint256 amount) public onlyServer {
    uint256 crudeAmount = getCrudeAmount(smartObjectId);
    if (crudeAmount < amount) revert InsufficientCrude();

    // TODO normal inventoryToEphemeral transfer
    removeCrude(smartObjectId, amount);
    addCrude(shipId, amount);
  }

  function removeLens(uint256 smartObjectId, address receiver) public onlyServer {
    if (CrudeLift.getLensId(smartObjectId) == 0) revert LensNotInserted();
    if (CrudeLift.getStartMiningTime(smartObjectId) != 0) revert CannotRemoveLensWhileMining();

    CrudeLift.setLensId(smartObjectId, 0);

    TransferItem[] memory items = new TransferItem[](1);
    items[0] = TransferItem({ inventoryItemId: CrudeLift.getLensId(smartObjectId), quantity: 1, owner: receiver });
    world().call(
      inventoryInteractSystemId,
      abi.encodeCall(InventoryInteractSystem.inventoryToEphemeralTransfer, (smartObjectId, receiver, items))
    );
  }

  function calculateCrudeMined(uint256 miningRate, uint256 duration) internal pure returns (uint256) {
    return (duration * miningRate) / 100_000;
  }

  function calculateCollapseChance(uint256 miningRate, uint256 stability) internal pure returns (uint256) {
    uint256 collapseChance = (stability * miningRate) / 100_000;

    return collapseChance > 100_000 ? 100_000 : collapseChance;
  }

  function addCrude(uint256 smartObjectId, uint256 amount) public onlyServer {
    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem({
      inventoryItemId: uint256(keccak256(abi.encodePacked("crude", CRUDE_MATTER))),
      owner: address(0),
      itemId: 0,
      typeId: CRUDE_MATTER,
      volume: amount,
      quantity: amount
    });

    world().call(
      inventorySystemId,
      abi.encodeCall(InventorySystem.createAndDepositItemsToInventory, (smartObjectId, items))
    );
  }

  function removeCrude(uint256 smartObjectId, uint256 amount) public onlyServer {
    uint256 crudeAmount = getCrudeAmount(smartObjectId);
    if (crudeAmount < amount) revert InsufficientCrude();

    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem({
      inventoryItemId: 0,
      owner: address(0),
      itemId: 0,
      typeId: CRUDE_MATTER,
      volume: amount,
      quantity: amount
    });

    world().call(inventorySystemId, abi.encodeCall(InventorySystem.withdrawFromInventory, (smartObjectId, items)));
  }

  function clearCrude(uint256 smartObjectId) public onlyServer {
    uint256 crudeAmount = getCrudeAmount(smartObjectId);
    if (crudeAmount == 0) return;

    removeCrude(smartObjectId, crudeAmount);
  }

  function getCrudeAmount(uint256 smartObjectId) public view returns (uint256) {
    uint256[] memory inventoryItems = Inventory.getItems(smartObjectId);
    uint256 foundCrudeId = 0;
    for (uint256 i = 0; i < inventoryItems.length; i++) {
      // how do i do this?
      if (EntityRecord.getTypeId(inventoryItems[i]) == CRUDE_MATTER) {
        foundCrudeId = inventoryItems[i];
        break;
      }
    }
    if (foundCrudeId == 0) return 0;

    return InventoryItemTable.getQuantity(smartObjectId, foundCrudeId);
  }
}
