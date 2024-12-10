pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { GlobalDeployableState } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/GlobalDeployableState.sol";
import { Characters } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/Characters.sol";
import { CharactersByAddress } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/CharactersByAddress.sol";
import { EntityRecordData, EntityMetadata } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/entity-record/types.sol";
import { SmartCharacterUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-character/SmartCharacterUtils.sol";
import { SmartStorageUnitUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-storage-unit/SmartStorageUnitUtils.sol";
import { DeployableUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableUtils.sol";
import { DeployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { SmartCharacterSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-character/SmartCharacterSystem.sol";
import { State, SmartObjectData } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/types.sol";
import { SmartStorageUnitSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-storage-unit/SmartStorageUnitSystem.sol";
import { Coord, WorldPosition } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/location/types.sol";

contract AnchorSSU is Script {
  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address player = vm.addr(deployerPrivateKey);

    ResourceId smartCharacterSystemId = SmartCharacterUtils.smartCharacterSystemId();
    ResourceId smartStorageSystemId = SmartStorageUnitUtils.smartStorageUnitSystemId();
    ResourceId deployableSystemId = DeployableUtils.deployableSystemId();

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);

    uint256 characterId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-2345")));
    address characterAddress = player;
    uint256 tribeId = 100;
    EntityRecordData memory entityRecord = EntityRecordData({ typeId: 123, itemId: 234, volume: 100 });

    EntityMetadata memory entityRecordMetadata = EntityMetadata({
      name: "name",
      dappURL: "dappURL",
      description: "description"
    });

    if (
      Characters.getCharacterAddress(characterId) == address(0) &&
      CharactersByAddress.getCharacterId(characterAddress) == 0
    ) {
      world.call(
        smartCharacterSystemId,
        abi.encodeCall(
          SmartCharacterSystem.createCharacter,
          (characterId, characterAddress, tribeId, entityRecord, entityRecordMetadata)
        )
      );
    }

    // check global state and resume if needed
    if (GlobalDeployableState.getIsPaused() == false) {
      world.call(deployableSystemId, abi.encodeCall(DeployableSystem.globalResume, ()));
    }

    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00001")));
    SmartObjectData memory smartObjectData = SmartObjectData({ owner: player, tokenURI: "test" });
    Coord memory position = Coord({ x: 1, y: 1, z: 1 });
    WorldPosition memory worldPosition = WorldPosition({ solarSystemId: 1, position: position });

    world.call(
      smartStorageSystemId,
      abi.encodeCall(
        SmartStorageUnitSystem.createAndAnchorSmartStorageUnit,
        (smartObjectId, entityRecord, smartObjectData, worldPosition, 10, 3600, 1000000000, 1000000000, 1000000000)
      )
    );

    vm.stopBroadcast();
  }
}
