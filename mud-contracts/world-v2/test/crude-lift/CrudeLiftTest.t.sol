// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { CrudeLift } from "../../src/namespaces/evefrontier/codegen/tables/CrudeLift.sol";
import { SmartAssembly } from "../../src/namespaces/evefrontier/codegen/tables/SmartAssembly.sol";
import { DeployableState } from "../../src/namespaces/evefrontier/codegen/tables/DeployableState.sol";
import { State, SmartObjectData } from "../../src/namespaces/evefrontier/systems/deployable/types.sol";
import { DeployableUtils } from "../../src/namespaces/evefrontier/systems/deployable/DeployableUtils.sol";
import { SmartCharacterUtils } from "../../src/namespaces/evefrontier/systems/smart-character/SmartCharacterUtils.sol";
import { FuelUtils } from "../../src/namespaces/evefrontier/systems/fuel/FuelUtils.sol";
import { CrudeLiftUtils } from "../../src/namespaces/evefrontier/systems/crude-lift/CrudeLiftUtils.sol";
import { DeployableSystem } from "../../src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { SmartCharacterSystem } from "../../src/namespaces/evefrontier/systems/smart-character/SmartCharacterSystem.sol";
import { EntityRecordData, EntityMetadata } from "../../src/namespaces/evefrontier/systems/entity-record/types.sol";
import { WorldPosition, Coord } from "../../src/namespaces/evefrontier/systems/location/types.sol";
import { CrudeLiftSystem } from "../../src/namespaces/evefrontier/systems/crude-lift/CrudeLiftSystem.sol";
import { FuelSystem } from "../../src/namespaces/evefrontier/systems/fuel/FuelSystem.sol";
import { CRUDE_LIFT } from "../../src/namespaces/evefrontier/systems/constants.sol";
import { InventoryItem } from "../../src/namespaces/evefrontier/systems/inventory/types.sol";
import { LENS } from "../../src/namespaces/evefrontier/systems/crude-lift/CrudeLiftSystem.sol";
import { EphemeralInventorySystem } from "../../src/namespaces/evefrontier/systems/inventory/EphemeralInventorySystem.sol";
import { InventoryUtils } from "../../src/namespaces/evefrontier/systems/inventory/InventoryUtils.sol";

contract CrudeLiftTest is MudTest {
  IBaseWorld world;

  string mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  uint256 alicePK = vm.deriveKey(mnemonic, 1);

  address alice = vm.addr(alicePK);
  uint256 characterId = 1111;
  uint256 tribeId = 1122;
  uint256 smartObjectId = 12345;
  uint256 lensId = 5678;
  uint256 riftId = 9012;

  EntityRecordData entityRecord;
  SmartObjectData smartObjectData;
  WorldPosition worldPosition;

  ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
  ResourceId characterSystemId = SmartCharacterUtils.smartCharacterSystemId();
  ResourceId crudeLiftSystemId = CrudeLiftUtils.crudeLiftSystemId();
  ResourceId fuelSystemId = FuelUtils.fuelSystemId();
  ResourceId ephemeralSystemId = InventoryUtils.ephemeralInventorySystemId();

  function setUp() public virtual override {
    super.setUp();
    world = IBaseWorld(worldAddress);

    entityRecord = EntityRecordData({ typeId: 123, itemId: 234, volume: 100 });

    EntityMetadata memory entityRecordMetadata = EntityMetadata({
      name: "name",
      dappURL: "dappURL",
      description: "description"
    });

    smartObjectData = SmartObjectData({ owner: alice, tokenURI: "test" });

    Coord memory position = Coord({ x: 1, y: 1, z: 1 });
    worldPosition = WorldPosition({ solarSystemId: 1, position: position });

    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.globalResume, ()));
    world.call(
      characterSystemId,
      abi.encodeCall(
        SmartCharacterSystem.createCharacter,
        (characterId, alice, tribeId, entityRecord, entityRecordMetadata)
      )
    );
  }

  function testAnchorCrudeLift() public {
    uint256 fuelUnitVolume = 100;
    uint256 fuelConsumptionIntervalInSeconds = 100;
    uint256 fuelMaxCapacity = 100;
    uint256 storageCapacity = 1000;
    uint256 ephemeralStorageCapacity = 1000;

    world.call(
      crudeLiftSystemId,
      abi.encodeCall(
        CrudeLiftSystem.createAndAnchorCrudeLift,
        (
          smartObjectId,
          entityRecord,
          smartObjectData,
          worldPosition,
          fuelUnitVolume,
          fuelConsumptionIntervalInSeconds,
          fuelMaxCapacity,
          storageCapacity,
          ephemeralStorageCapacity
        )
      )
    );

    world.call(fuelSystemId, abi.encodeCall(FuelSystem.depositFuel, (smartObjectId, 1)));
    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.bringOnline, (smartObjectId)));

    assertEq(SmartAssembly.getSmartAssemblyType(smartObjectId), CRUDE_LIFT);
    assertEq(uint8(DeployableState.getCurrentState(smartObjectId)), uint8(State.ONLINE));
  }

  function testInsertLens() public {
    testAnchorCrudeLift();

    // Create lens entity record
    EntityRecordData memory lensEntityRecord = EntityRecordData({ typeId: LENS, itemId: lensId, volume: 100 });

    // Create lens inventory item
    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem({
      inventoryItemId: lensId,
      owner: alice,
      itemId: lensId,
      typeId: LENS,
      volume: 100,
      quantity: 1
    });

    // Deposit lens into crude lift's ephemeral inventory
    world.call(
      ephemeralSystemId,
      abi.encodeCall(EphemeralInventorySystem.createAndDepositItemsToEphemeralInventory, (smartObjectId, alice, items))
    );

    // Now insert the lens
    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.insertLens, (smartObjectId, alice)));

    assertEq(CrudeLift.getLensId(smartObjectId), lensId);
  }

  function testStartMining() public {
    testInsertLens();

    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.startMining, (smartObjectId, riftId)));

    assertEq(CrudeLift.getMiningRiftId(smartObjectId), riftId);
    assertTrue(CrudeLift.getStartMiningTime(smartObjectId) > 0);
  }

  function testStopMining() public {
    testStartMining();

    vm.warp(block.timestamp + 100); // Advance time by 100 seconds

    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.stopMining, (smartObjectId)));

    assertEq(CrudeLift.getStartMiningTime(smartObjectId), 0);
  }

  function testRemoveLens() public {
    testInsertLens();

    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.removeLens, (smartObjectId, alice)));

    assertEq(CrudeLift.getLensId(smartObjectId), 0);
  }

  function testRevertStartMiningWithoutLens() public {
    testAnchorCrudeLift();

    vm.expectRevert(CrudeLiftSystem.LensNotInserted.selector);
    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.startMining, (smartObjectId, riftId)));
  }

  function testRevertStartMiningWhileMining() public {
    testStartMining();

    vm.expectRevert(CrudeLiftSystem.AlreadyMining.selector);
    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.startMining, (smartObjectId, riftId)));
  }

  function testRevertStopMiningWhenNotMining() public {
    testInsertLens();

    vm.expectRevert(CrudeLiftSystem.NotMining.selector);
    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.stopMining, (smartObjectId)));
  }

  function testRevertRemoveLensWhileMining() public {
    testStartMining();

    vm.expectRevert(CrudeLiftSystem.CannotRemoveLensWhileMining.selector);
    world.call(crudeLiftSystemId, abi.encodeCall(CrudeLiftSystem.removeLens, (smartObjectId, alice)));
  }
}
