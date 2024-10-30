pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { GlobalDeployableState } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/GlobalDeployableState.sol";
import { DeployableUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableUtils.sol";
import { DeployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { State, SmartObjectData } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/types.sol";
import { Coord, WorldPosition } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/location/types.sol";
import { SmartTurretSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-turret/SmartTurretSystem.sol";
import { SmartTurretUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-turret/SmartTurretUtils.sol";
import { EntityRecordData, EntityMetadata } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/entity-record/types.sol";

contract AnchorSmartTurret is Script {
  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address player = vm.addr(deployerPrivateKey);

    ResourceId smartTurretSystemId = SmartTurretUtils.smartTurretSystemId();
    ResourceId deployableSystemId = DeployableUtils.deployableSystemId();

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);

    // check global state and resume if needed
    if (GlobalDeployableState.getIsPaused() == false) {
      world.call(deployableSystemId, abi.encodeCall(DeployableSystem.globalResume, ()));
    }

    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00002")));
    EntityRecordData memory entityRecord = EntityRecordData({ typeId: 123, itemId: 234, volume: 100 });
    SmartObjectData memory smartObjectData = SmartObjectData({ owner: player, tokenURI: "test" });
    Coord memory position = Coord({ x: 1, y: 1, z: 1 });
    WorldPosition memory worldPosition = WorldPosition({ solarSystemId: 1, position: position });

    world.call(
      smartTurretSystemId,
      abi.encodeCall(
        SmartTurretSystem.createAndAnchorSmartTurret,
        (smartObjectId, entityRecord, smartObjectData, worldPosition, 10, 3600, 1000000000)
      )
    );

    vm.stopBroadcast();
  }
}
