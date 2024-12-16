// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { SmartGateConfig } from "../../src/namespaces/evefrontier/codegen/tables/SmartGateConfig.sol";
import { DeployableState } from "../../src/namespaces/evefrontier/codegen/tables/DeployableState.sol";
import { SmartAssembly } from "../../src/namespaces/evefrontier/codegen/tables/SmartAssembly.sol";
import { State, SmartObjectData } from "../../src/namespaces/evefrontier/systems/deployable/types.sol";
import { SmartGateCustomMock } from "./SmartGateCustomMock.sol";
import { DeployableUtils } from "../../src/namespaces/evefrontier/systems/deployable/DeployableUtils.sol";
import { SmartCharacterUtils } from "../../src/namespaces/evefrontier/systems/smart-character/SmartCharacterUtils.sol";
import { SmartGateUtils } from "../../src/namespaces/evefrontier/systems/smart-gate/SmartGateUtils.sol";
import { FuelUtils } from "../../src/namespaces/evefrontier/systems/fuel/FuelUtils.sol";
import { DeployableSystem } from "../../src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { SmartCharacterSystem } from "../../src/namespaces/evefrontier/systems/smart-character/SmartCharacterSystem.sol";
import { EntityRecordData, EntityMetadata } from "../../src/namespaces/evefrontier/systems/entity-record/types.sol";
import { WorldPosition, Coord } from "../../src/namespaces/evefrontier/systems/location/types.sol";
import { FuelSystem } from "../../src/namespaces/evefrontier/systems/fuel/FuelSystem.sol";
import { SmartGateSystem } from "../../src/namespaces/evefrontier/systems/smart-gate/SmartGateSystem.sol";

import { SMART_GATE } from "../../src/namespaces/evefrontier/systems/constants.sol";

contract SmartGateTest is MudTest {
  IBaseWorld world;

  SmartGateCustomMock smartGateCustomMock;
  bytes14 constant CUSTOM_NAMESPACE = "custom-namespa";

  ResourceId SMART_GATE_CUSTOM_MOCK_SYSTEM_ID;

  string mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  uint256 alicePK = vm.deriveKey(mnemonic, 1);

  address deployer = vm.addr(deployerPK); // ADMIN
  address alice = vm.addr(alicePK); // BUILDER

  uint256 sourceGateId = 1234;
  uint256 destinationGateId = 1235;

  uint256 characterId = 1111;
  uint256 tribeId = 1122;
  string tokenCID = "Qm1234abcdxxxx";
  uint256 fuelUnitVolume = 100;
  uint256 fuelConsumptionIntervalInSeconds = 100;
  uint256 fuelMaxCapacity = 100;
  uint256 maxDistance = 100000000 * 1e18;

  SmartObjectData smartObjectData;
  EntityRecordData entityRecord;
  WorldPosition worldPosition;

  ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
  ResourceId characterSystemId = SmartCharacterUtils.smartCharacterSystemId();
  ResourceId smartGateSystemId = SmartGateUtils.smartGateSystemId();
  ResourceId fuelSystemId = FuelUtils.fuelSystemId();

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

    // BUILDER register a custom namespace
    vm.startPrank(alice);
    world.registerNamespace(WorldResourceIdLib.encodeNamespace(CUSTOM_NAMESPACE));

    SMART_GATE_CUSTOM_MOCK_SYSTEM_ID = ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, CUSTOM_NAMESPACE, "SmartGateCustomM")))
    );
    // BUILER deploy and register mock
    smartGateCustomMock = new SmartGateCustomMock();
    world.registerSystem(SMART_GATE_CUSTOM_MOCK_SYSTEM_ID, smartGateCustomMock, true);
    world.registerFunctionSelector(SMART_GATE_CUSTOM_MOCK_SYSTEM_ID, "canJump(uint256,uint256,uint256)");

    vm.stopPrank();

    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.globalResume, ()));
    world.call(
      characterSystemId,
      abi.encodeCall(
        SmartCharacterSystem.createCharacter,
        (characterId, alice, tribeId, entityRecord, entityRecordMetadata)
      )
    );
  }

  function testAnchorSmartGate(uint256 smartObjectId) public {
    vm.assume(smartObjectId != 0);

    world.call(
      smartGateSystemId,
      abi.encodeCall(
        SmartGateSystem.createAndAnchorSmartGate,
        (
          smartObjectId,
          entityRecord,
          smartObjectData,
          worldPosition,
          fuelUnitVolume,
          fuelConsumptionIntervalInSeconds,
          fuelMaxCapacity,
          maxDistance
        )
      )
    );

    world.call(fuelSystemId, abi.encodeCall(FuelSystem.depositFuel, (smartObjectId, 1)));
    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.bringOnline, (smartObjectId)));
    assertEq(SmartAssembly.getSmartAssemblyType(smartObjectId), SMART_GATE);

    State currentState = DeployableState.getCurrentState(smartObjectId);
    assertEq(uint8(currentState), uint8(State.ONLINE));
  }

  function testLinkSmartGates() public {
    world.call(smartGateSystemId, abi.encodeCall(SmartGateSystem.linkSmartGates, (sourceGateId, destinationGateId)));

    bytes memory returnData = world.call(
      smartGateSystemId,
      abi.encodeCall(SmartGateSystem.isGateLinked, (sourceGateId, destinationGateId))
    );
    assert(abi.decode(returnData, (bool)));

    returnData = world.call(
      smartGateSystemId,
      abi.encodeCall(SmartGateSystem.isGateLinked, (destinationGateId, sourceGateId))
    );

    assert(abi.decode(returnData, (bool)));
  }

  function tesRevertLinkSmartGates() public {
    vm.expectRevert(
      abi.encodeWithSelector(
        SmartGateSystem.SmartGate_SameSourceAndDestination.selector,
        sourceGateId,
        destinationGateId
      )
    );

    world.call(smartGateSystemId, abi.encodeCall(SmartGateSystem.linkSmartGates, (sourceGateId, sourceGateId)));
  }

  function testUnlinkSmartGates() public {
    testLinkSmartGates();

    world.call(smartGateSystemId, abi.encodeCall(SmartGateSystem.unlinkSmartGates, (sourceGateId, destinationGateId)));

    bytes memory returnData = world.call(
      smartGateSystemId,
      abi.encodeCall(SmartGateSystem.isGateLinked, (sourceGateId, destinationGateId))
    );

    assert(!abi.decode(returnData, (bool)));
  }

  function testRevertExistingLink() public {
    testLinkSmartGates();
    vm.expectRevert(
      abi.encodeWithSelector(SmartGateSystem.SmartGate_GateAlreadyLinked.selector, sourceGateId, destinationGateId)
    );

    world.call(smartGateSystemId, abi.encodeCall(SmartGateSystem.linkSmartGates, (sourceGateId, destinationGateId)));
  }

  function testLinkRevertDistanceAboveMax() public {
    uint256 smartObjectIdA = 234;
    uint256 smartObjectIdB = 345;
    WorldPosition memory worldPositionA = WorldPosition({
      solarSystemId: 1,
      position: Coord({ x: 10000, y: 10000, z: 10000 })
    });

    WorldPosition memory worldPositionB = WorldPosition({
      solarSystemId: 1,
      position: Coord({ x: 1000000000, y: 1000000000, z: 1000000000 })
    });

    world.call(
      smartGateSystemId,
      abi.encodeCall(
        SmartGateSystem.createAndAnchorSmartGate,
        (
          smartObjectIdA,
          entityRecord,
          smartObjectData,
          worldPositionA,
          fuelUnitVolume,
          fuelConsumptionIntervalInSeconds,
          fuelMaxCapacity,
          1 // maxDistance
        )
      )
    );

    world.call(fuelSystemId, abi.encodeCall(FuelSystem.depositFuel, (smartObjectIdA, 1)));
    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.bringOnline, (smartObjectIdA)));

    world.call(
      smartGateSystemId,
      abi.encodeCall(
        SmartGateSystem.createAndAnchorSmartGate,
        (
          smartObjectIdB,
          entityRecord,
          smartObjectData,
          worldPositionB,
          fuelUnitVolume,
          fuelConsumptionIntervalInSeconds,
          fuelMaxCapacity,
          1 // maxDistance
        )
      )
    );

    world.call(fuelSystemId, abi.encodeCall(FuelSystem.depositFuel, (smartObjectIdB, 1)));
    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.bringOnline, (smartObjectIdB)));

    vm.expectRevert(
      abi.encodeWithSelector(SmartGateSystem.SmartGate_NotWithtinRange.selector, smartObjectIdA, smartObjectIdB)
    );
    world.call(smartGateSystemId, abi.encodeCall(SmartGateSystem.linkSmartGates, (smartObjectIdA, smartObjectIdB)));
  }

  function testRevertUnlinkSmartGates() public {
    vm.expectRevert(
      abi.encodeWithSelector(SmartGateSystem.SmartGate_GateNotLinked.selector, sourceGateId, destinationGateId)
    );

    world.call(smartGateSystemId, abi.encodeCall(SmartGateSystem.unlinkSmartGates, (sourceGateId, destinationGateId)));
  }

  function testConfigureSmartGate() public {
    world.call(
      smartGateSystemId,
      abi.encodeCall(SmartGateSystem.configureSmartGate, (sourceGateId, SMART_GATE_CUSTOM_MOCK_SYSTEM_ID))
    );

    ResourceId systemId = SmartGateConfig.getSystemId(sourceGateId);
    assertEq(ResourceId.unwrap(systemId), ResourceId.unwrap(SMART_GATE_CUSTOM_MOCK_SYSTEM_ID));
  }

  function testCanJump() public {
    testAnchorSmartGate(sourceGateId);
    testAnchorSmartGate(destinationGateId);
    testLinkSmartGates();
    bytes memory returnData = world.call(
      smartGateSystemId,
      abi.encodeCall(SmartGateSystem.canJump, (characterId, sourceGateId, destinationGateId))
    );

    assert(abi.decode(returnData, (bool)));
  }

  function testCanJumpFalse() public {
    testConfigureSmartGate();

    testAnchorSmartGate(sourceGateId);
    testAnchorSmartGate(destinationGateId);
    testLinkSmartGates();

    bytes memory returnData = world.call(
      smartGateSystemId,
      abi.encodeCall(SmartGateSystem.canJump, (characterId, sourceGateId, destinationGateId))
    );

    assert(!abi.decode(returnData, (bool)));
  }

  function testCanJump2way() public {
    testAnchorSmartGate(sourceGateId);
    testAnchorSmartGate(destinationGateId);
    testLinkSmartGates();
    bytes memory returnData = world.call(
      smartGateSystemId,
      abi.encodeCall(SmartGateSystem.canJump, (characterId, destinationGateId, sourceGateId))
    );

    assert(abi.decode(returnData, (bool)));
  }
}
