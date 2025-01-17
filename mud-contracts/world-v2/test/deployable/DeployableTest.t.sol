// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { State, SmartObjectData } from "../../src/namespaces/evefrontier/systems/deployable/types.sol";

import { IWorld } from "../../src/codegen/world/IWorld.sol";
import { State } from "../../src/codegen/common.sol";
import { GlobalDeployableState, DeployableState, DeployableToken } from "../../src/namespaces/evefrontier/codegen/index.sol";
import { SmartCharacterSystem } from "../../src/namespaces/evefrontier/systems/smart-character/SmartCharacterSystem.sol";
import { GlobalDeployableStateData } from "../../src/namespaces/evefrontier/codegen/tables/GlobalDeployableState.sol";
import { DeployableState, DeployableStateData } from "../../src/namespaces/evefrontier/codegen/tables/DeployableState.sol";
import { Location, LocationData } from "../../src/namespaces/evefrontier/codegen/tables/Location.sol";
import { Fuel, FuelData } from "../../src/namespaces/evefrontier/codegen/tables/Fuel.sol";
import { DeployableSystemLib, deployableSystem } from "../../src/namespaces/evefrontier/codegen/systems/DeployableSystemLib.sol";
import { SmartCharacterSystemLib, smartCharacterSystem } from "../../src/namespaces/evefrontier/codegen/systems/SmartCharacterSystemLib.sol";
import { FuelSystemLib, fuelSystem } from "../../src/namespaces/evefrontier/codegen/systems/FuelSystemLib.sol";
import { EntityRecordData, EntityMetadata } from "../../src/namespaces/evefrontier/systems/entity-record/types.sol";
import { CreateAndAnchorDeployableParams } from "../../src/namespaces/evefrontier/systems/deployable/types.sol";

import { ONE_UNIT_IN_WEI } from "../../src/namespaces/evefrontier/systems/constants.sol";

import { IWorldWithContext } from "@eveworld/smart-object-framework-v2/src/IWorldWithContext.sol";
import { EveTest } from "../EveTest.sol";

import "forge-std/console.sol";

contract DeployableTest is EveTest {
  uint256 characterId = 123;

  uint256 tribeId = 100;
  SmartObjectData smartObjectData;

  function setUp() public virtual override {
    super.setUp();

    EntityRecordData memory entityRecord = EntityRecordData({ typeId: 123, itemId: 234, volume: 100 });

    EntityMetadata memory entityRecordMetadata = EntityMetadata({
      name: "name",
      dappURL: "dappURL",
      description: "description"
    });

    smartObjectData = SmartObjectData({ owner: alice, tokenURI: "test" });

    smartCharacterSystem.createCharacter(characterId, alice, tribeId, entityRecord, entityRecordMetadata);
  }

  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  function testRegisterDeployable(
    uint256 smartObjectId,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity
  ) public {
    vm.assume(smartObjectId != 0);
    vm.assume(fuelUnitVolume != 0);
    vm.assume(fuelConsumptionIntervalInSeconds >= 1);
    vm.assume(fuelMaxCapacity != 0);

    deployableSystem.globalResume();

    DeployableStateData memory data = DeployableStateData({
      createdAt: block.timestamp,
      previousState: State.NULL,
      currentState: State.UNANCHORED,
      isValid: true,
      anchoredAt: block.timestamp,
      updatedBlockNumber: block.number,
      updatedBlockTime: block.timestamp
    });

    deployableSystem.registerDeployable(
      smartObjectId,
      smartObjectData,
      fuelUnitVolume,
      fuelConsumptionIntervalInSeconds,
      fuelMaxCapacity
    );

    DeployableStateData memory tableData = DeployableState.get(smartObjectId);

    assertEq(data.createdAt, tableData.createdAt);
    assertEq(uint8(data.currentState), uint8(tableData.currentState));
    assertEq(data.updatedBlockNumber, tableData.updatedBlockNumber);
  }

  function testAnchor(
    uint256 smartObjectId,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    LocationData memory location
  ) public {
    vm.assume(smartObjectId != 0);
    testRegisterDeployable(smartObjectId, fuelUnitVolume, fuelConsumptionIntervalInSeconds, fuelMaxCapacity);

    deployableSystem.anchor(smartObjectId, location);

    LocationData memory tableData = Location.get(smartObjectId);

    assertEq(location.solarSystemId, tableData.solarSystemId);
    assertEq(location.x, tableData.x);
    assertEq(location.y, tableData.y);
    assertEq(location.z, tableData.z);
    assertEq(uint8(State.ANCHORED), uint8(DeployableState.getCurrentState(smartObjectId)));
  }

  function testBringOnline(
    uint256 smartObjectId,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    LocationData memory location
  ) public {
    vm.assume(smartObjectId != 0);

    testAnchor(smartObjectId, fuelUnitVolume, fuelConsumptionIntervalInSeconds, fuelMaxCapacity, location);
    vm.assume(fuelUnitVolume < type(uint64).max / 2);
    vm.assume(fuelUnitVolume < fuelMaxCapacity);

    fuelSystem.depositFuel(smartObjectId, 1);

    deployableSystem.bringOnline(smartObjectId);
    assertEq(uint8(State.ONLINE), uint8(DeployableState.getCurrentState(smartObjectId)));
  }

  function testBringOffline(
    uint256 smartObjectId,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    LocationData memory location
  ) public {
    vm.assume(smartObjectId != 0);
    testBringOnline(smartObjectId, fuelUnitVolume, fuelConsumptionIntervalInSeconds, fuelMaxCapacity, location);
    deployableSystem.bringOffline(smartObjectId);
    assertEq(uint8(State.ANCHORED), uint8(DeployableState.getCurrentState(smartObjectId)));
  }

  function testUnanchor(
    uint256 smartObjectId,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    LocationData memory location
  ) public {
    vm.assume(smartObjectId != 0);
    testAnchor(smartObjectId, fuelUnitVolume, fuelConsumptionIntervalInSeconds, fuelMaxCapacity, location);
    deployableSystem.unanchor(smartObjectId);
    assertEq(uint8(State.UNANCHORED), uint8(DeployableState.getCurrentState(smartObjectId)));
  }

  function testDestroyDeployable(
    uint256 smartObjectId,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    LocationData memory location
  ) public {
    vm.assume(smartObjectId != 0);
    testAnchor(smartObjectId, fuelUnitVolume, fuelConsumptionIntervalInSeconds, fuelMaxCapacity, location);
    deployableSystem.destroyDeployable(smartObjectId);
    assertEq(uint8(State.DESTROYED), uint8(DeployableState.getCurrentState(smartObjectId)));
  }

  function testCreateAndAnchorDeployable(
    uint256 smartObjectId,
    string memory smartAssemblyType,
    EntityRecordData memory entityRecordData,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    LocationData memory locationData
  ) public {
    vm.assume(smartObjectId != 0);
    vm.assume(fuelUnitVolume != 0);
    vm.assume(fuelConsumptionIntervalInSeconds >= 1);
    vm.assume(fuelMaxCapacity != 0);
    vm.assume((keccak256(abi.encodePacked(smartAssemblyType)) != keccak256(abi.encodePacked(""))));

    vm.startPrank(deployer);

    deployableSystem.globalResume();
    deployableSystem.createAndAnchorDeployable(
      CreateAndAnchorDeployableParams({
        smartObjectId: smartObjectId,
        smartAssemblyType: smartAssemblyType,
        entityRecordData: entityRecordData,
        smartObjectData: smartObjectData,
        fuelUnitVolume: fuelUnitVolume,
        fuelConsumptionIntervalInSeconds: fuelConsumptionIntervalInSeconds,
        fuelMaxCapacity: fuelMaxCapacity,
        locationData: locationData
      })
    );

    vm.stopPrank();

    LocationData memory location = Location.get(smartObjectId);

    assertEq(locationData.solarSystemId, location.solarSystemId);
    assertEq(locationData.x, location.x);
    assertEq(locationData.y, location.y);
    assertEq(locationData.z, location.z);
    assertEq(uint8(State.ANCHORED), uint8(DeployableState.getCurrentState(smartObjectId)));
  }
}
