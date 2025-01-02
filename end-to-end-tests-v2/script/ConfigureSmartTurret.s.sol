pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { GlobalDeployableState } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/GlobalDeployableState.sol";
import { DeployableUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableUtils.sol";
import { DeployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { State, SmartObjectData } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/types.sol";
import { SmartTurretSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-turret/SmartTurretSystem.sol";
import { SmartTurretUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-turret/SmartTurretUtils.sol";
import { FuelSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/fuel/FuelSystem.sol";
import { FuelUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/fuel/FuelUtils.sol";
import { TargetPriority, Turret, SmartTurretTarget } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-turret/types.sol";

contract ConfigureSmartTurret is Script {
  using WorldResourceIdInstance for ResourceId;

  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address player = vm.addr(deployerPrivateKey);

    ResourceId smartTurretSystemId = SmartTurretUtils.smartTurretSystemId();
    ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
    ResourceId fuelSystemId = FuelUtils.fuelSystemId();

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);

    // check global state and resume if needed
    if (GlobalDeployableState.getIsPaused() == false) {
      world.call(deployableSystemId, abi.encodeCall(DeployableSystem.globalResume, ()));
    }

    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00002")));

    world.call(fuelSystemId, abi.encodeCall(FuelSystem.depositFuel, (smartObjectId, 100000)));
    world.call(deployableSystemId, abi.encodeCall(DeployableSystem.bringOnline, (smartObjectId)));

    SmartTurretTestSystem smartTurretTestSystem = new SmartTurretTestSystem();
    ResourceId smartTurretTestSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: "testnamespace",
      name: "SmartTurretTestS"
    });

    // register the smart turret system
    world.registerNamespace(smartTurretTestSystemId.getNamespaceId());
    world.registerSystem(smartTurretTestSystemId, smartTurretTestSystem, true);
    //register the function selector
    world.registerFunctionSelector(
      smartTurretTestSystemId,
      "inProximity(uint256,uint256,((uint256,uint256,uint256,uint256,uint256,uint256),uint256)[],(uint256,uint256,uint256),(uint256,uint256,uint256,uint256,uint256,uint256))"
    );

    world.call(
      smartTurretSystemId,
      abi.encodeCall(SmartTurretSystem.configureSmartTurret, (smartObjectId, smartTurretTestSystemId))
    );

    //Execute inProximity view function and see what is returns
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });
    uint256 characterId = 11111;

    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: characterId,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    bytes memory returnData = world.call(
      smartTurretSystemId,
      abi.encodeCall(
        SmartTurretTestSystem.inProximity,
        (smartObjectId, characterId, priorityQueue, turret, turretTarget)
      )
    );
    TargetPriority[] memory returnTargetQueue = abi.decode(returnData, (TargetPriority[]));

    console.log(returnTargetQueue.length);

    vm.stopBroadcast();
  }
}

//Mock Contract for testing
contract SmartTurretTestSystem is System {
  function inProximity(
    uint256 smartTurretId,
    uint256 turretOwnerCharacterId,
    TargetPriority[] memory priorityQueue,
    Turret memory turret,
    SmartTurretTarget memory turretTarget
  ) public returns (TargetPriority[] memory returnTargetQueue) {
    //TODO: Implement the logic for the system
    return priorityQueue;
  }

  function aggression(
    uint256 smartTurretId,
    uint256 turretOwnerCharacterId,
    TargetPriority[] memory priorityQueue,
    Turret memory turret,
    SmartTurretTarget memory aggressor,
    SmartTurretTarget memory victim
  ) public returns (TargetPriority[] memory returnTargetQueue) {
    return returnTargetQueue;
  }
}
