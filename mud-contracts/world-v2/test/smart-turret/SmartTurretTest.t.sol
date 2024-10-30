// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { SmartAssembly } from "../../src/namespaces/evefrontier/codegen/tables/SmartAssembly.sol";
import { SmartTurretConfig } from "../../src/namespaces/evefrontier/codegen/tables/SmartTurretConfig.sol";
import { State, SmartObjectData } from "../../src/namespaces/evefrontier/systems/deployable/types.sol";
import { DeployableUtils } from "../../src/namespaces/evefrontier/systems/deployable/DeployableUtils.sol";
import { SmartCharacterUtils } from "../../src/namespaces/evefrontier/systems/smart-character/SmartCharacterUtils.sol";
import { FuelUtils } from "../../src/namespaces/evefrontier/systems/fuel/FuelUtils.sol";
import { SmartTurretUtils } from "../../src/namespaces/evefrontier/systems/smart-turret/SmartTurretUtils.sol";
import { SmartTurretCustomMock } from "./SmartTurretCustomMock.sol";
import { DeployableSystem } from "../../src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { SmartCharacterSystem } from "../../src/namespaces/evefrontier/systems/smart-character/SmartCharacterSystem.sol";
import { EntityRecordData, EntityMetadata } from "../../src/namespaces/evefrontier/systems/entity-record/types.sol";
import { WorldPosition, Coord } from "../../src/namespaces/evefrontier/systems/location/types.sol";
import { SmartTurretSystem } from "../../src/namespaces/evefrontier/systems/smart-turret/SmartTurretSystem.sol";
import { FuelSystem } from "../../src/namespaces/evefrontier/systems/fuel/FuelSystem.sol";

import { SMART_TURRET } from "../../src/namespaces/evefrontier/systems/constants.sol";
import { TargetPriority, Turret, SmartTurretTarget } from "../../src/namespaces/evefrontier/systems/smart-turret/types.sol";

/**
 * @title SmartTurretTest
 * @dev Not including Fuzz test as it has issues
 */
contract SmartTurretTest is MudTest {
  IBaseWorld world;

  SmartTurretCustomMock smartTurretCustomMock;
  bytes14 constant CUSTOM_NAMESPACE = "custom-namespa";

  ResourceId SMART_TURRET_CUSTOM_MOCK_SYSTEM_ID;

  uint256 smartObjectId = 1234;
  uint256 characterId = 11111;

  string mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  uint256 alicePK = vm.deriveKey(mnemonic, 1);

  address deployer = vm.addr(deployerPK); // ADMIN
  address alice = vm.addr(alicePK); // BUILDER
  uint256 tribeId = 100;
  SmartObjectData smartObjectData;
  EntityRecordData entityRecord;
  WorldPosition worldPosition;

  ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
  ResourceId characterSystemId = SmartCharacterUtils.smartCharacterSystemId();
  ResourceId turretSystemId = SmartTurretUtils.smartTurretSystemId();
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
    SMART_TURRET_CUSTOM_MOCK_SYSTEM_ID = ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, CUSTOM_NAMESPACE, "SmartTurretCusto")))
    );
    // BUILER deploy and register mock
    smartTurretCustomMock = new SmartTurretCustomMock();
    world.registerSystem(SMART_TURRET_CUSTOM_MOCK_SYSTEM_ID, smartTurretCustomMock, true);
    world.registerFunctionSelector(
      SMART_TURRET_CUSTOM_MOCK_SYSTEM_ID,
      "inProximity(uint256,uint256,((uint256,uint256,uint256,uint256,uint256,uint256),uint256)[],(uint256,uint256,uint256),(uint256,uint256,uint256,uint256,uint256,uint256))"
    );
    world.registerFunctionSelector(
      SMART_TURRET_CUSTOM_MOCK_SYSTEM_ID,
      "aggression(uint256,uint256,((uint256,uint256,uint256,uint256,uint256,uint256),uint256)[],(uint256,uint256,uint256),(uint256,uint256,uint256,uint256,uint256,uint256),(uint256,uint256,uint256,uint256,uint256,uint256))"
    );
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

  function testAnchorSmartTurret() public {
    uint256 fuelUnitVolume = 100;
    uint256 fuelConsumptionIntervalInSeconds = 100;
    uint256 fuelMaxCapacity = 100;

    world.call(
      turretSystemId,
      abi.encodeCall(
        SmartTurretSystem.createAndAnchorSmartTurret,
        (
          smartObjectId,
          entityRecord,
          smartObjectData,
          worldPosition,
          fuelUnitVolume,
          fuelConsumptionIntervalInSeconds,
          fuelMaxCapacity
        )
      )
    );

    world.call(fuelSystemId, abi.encodeCall(FuelSystem.depositFuel, (smartObjectId, 1)));
    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.bringOnline, (smartObjectId)));

    assertEq(SmartAssembly.getSmartAssemblyType(smartObjectId), SMART_TURRET);
  }

  function testConfigureSmartTurret() public {
    testAnchorSmartTurret();
    world.call(
      turretSystemId,
      abi.encodeCall(SmartTurretSystem.configureSmartTurret, (smartObjectId, SMART_TURRET_CUSTOM_MOCK_SYSTEM_ID))
    );

    ResourceId systemId = SmartTurretConfig.get(smartObjectId);
    assertEq(ResourceId.unwrap(systemId), ResourceId.unwrap(SMART_TURRET_CUSTOM_MOCK_SYSTEM_ID));
  }

  function testInProximity() public {
    testConfigureSmartTurret();
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });

    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 11111,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    bytes memory returnData = world.call(
      turretSystemId,
      abi.encodeCall(SmartTurretSystem.inProximity, (smartObjectId, characterId, priorityQueue, turret, turretTarget))
    );

    TargetPriority[] memory returnTargetQueue = abi.decode(returnData, (TargetPriority[]));

    assertEq(returnTargetQueue.length, 1);
    assertEq(returnTargetQueue[0].weight, 100);
  }

  function testInProximityDefaultLogic() public {
    testAnchorSmartTurret();
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });

    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 11112,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    bytes memory returnData = world.call(
      turretSystemId,
      abi.encodeCall(SmartTurretSystem.inProximity, (smartObjectId, characterId, priorityQueue, turret, turretTarget))
    );

    TargetPriority[] memory returnTargetQueue = abi.decode(returnData, (TargetPriority[]));

    assertEq(returnTargetQueue.length, 2);
  }

  function testInProximityWrongCorpId() public {
    testConfigureSmartTurret();
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 5555,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    bytes memory returnData = world.call(
      turretSystemId,
      abi.encodeCall(SmartTurretSystem.inProximity, (smartObjectId, characterId, priorityQueue, turret, turretTarget))
    );

    TargetPriority[] memory returnTargetQueue = abi.decode(returnData, (TargetPriority[]));

    assertEq(returnTargetQueue.length, 0);
  }

  function testAggression() public {
    testConfigureSmartTurret();
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 4444,
      hpRatio: 50,
      shieldRatio: 50,
      armorRatio: 50
    });
    SmartTurretTarget memory aggressor = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 5555,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    SmartTurretTarget memory victim = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 6666,
      hpRatio: 80,
      shieldRatio: 100,
      armorRatio: 100
    });

    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    bytes memory returnData = world.call(
      turretSystemId,
      abi.encodeCall(
        SmartTurretSystem.aggression,
        (smartObjectId, characterId, priorityQueue, turret, aggressor, victim)
      )
    );

    TargetPriority[] memory returnTargetQueue = abi.decode(returnData, (TargetPriority[]));

    assertEq(returnTargetQueue.length, 1);
    assertEq(returnTargetQueue[0].weight, 100);
  }

  function testAggressionDefaultLogic() public {
    testAnchorSmartTurret();
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 4444,
      hpRatio: 50,
      shieldRatio: 50,
      armorRatio: 50
    });
    SmartTurretTarget memory aggressor = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 5555,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    SmartTurretTarget memory victim = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 6666,
      hpRatio: 80,
      shieldRatio: 100,
      armorRatio: 100
    });

    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    bytes memory returnData = world.call(
      turretSystemId,
      abi.encodeCall(
        SmartTurretSystem.aggression,
        (smartObjectId, characterId, priorityQueue, turret, aggressor, victim)
      )
    );

    TargetPriority[] memory returnTargetQueue = abi.decode(returnData, (TargetPriority[]));

    assertEq(returnTargetQueue.length, 2);
    assertEq(returnTargetQueue[1].weight, 1);
  }

  function revertInProximity() public {
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 5555,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    vm.expectRevert(abi.encodeWithSelector(SmartTurretSystem.SmartTurret_NotConfigured.selector, smartObjectId));

    world.call(
      turretSystemId,
      abi.encodeCall(SmartTurretSystem.inProximity, (smartObjectId, characterId, priorityQueue, turret, turretTarget))
    );
  }

  function revertInProximityIncorrectState() public {
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 5555,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    vm.expectRevert(
      abi.encodeWithSelector(DeployableSystem.Deployable_IncorrectState.selector, smartObjectId, State.UNANCHORED)
    );

    world.call(
      turretSystemId,
      abi.encodeCall(SmartTurretSystem.inProximity, (smartObjectId, characterId, priorityQueue, turret, turretTarget))
    );
  }
}
