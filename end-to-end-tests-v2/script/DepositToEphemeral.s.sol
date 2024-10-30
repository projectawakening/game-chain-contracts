pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { InventoryItem } from "@eveworld/world-v2/src/systems/inventory/types.sol";
import { InventoryUtils } from "@eveworld/world-v2/src/systems/inventory/InventoryUtils.sol";
import { EphemeralInventorySystem } from "@eveworld/world-v2/src/systems/inventory/EphemeralInventorySystem.sol";

import { EntityRecordData, EntityMetadata } from "@eveworld/world-v2/src/systems/entity-record/types.sol";
import { SmartCharacterSystem } from "@eveworld/world-v2/src/systems/smart-character/SmartCharacterSystem.sol";
import { SmartCharacterUtils } from "@eveworld/world-v2/src/systems/smart-character/SmartCharacterUtils.sol";

contract DepositToEphemeral is Script {
  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    string memory mnemonic = "test test test test test test test test test test test junk";
    uint256 alice = vm.deriveKey(mnemonic, 2);
    uint256 bob = vm.deriveKey(mnemonic, 3);

    address ephemeralInvOwner1 = vm.addr(alice);
    address ephemeralInvOwner2 = vm.addr(bob);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);
    ResourceId ephemeralSystemId = InventoryUtils.ephemeralInventorySystemId();
    ResourceId characterSystemId = SmartCharacterUtils.smartCharacterSystemId();

    uint256 tribeId = 100;
    EntityRecordData memory entityRecord = EntityRecordData({ typeId: 123, itemId: 234, volume: 100 });

    EntityMetadata memory entityRecordMetadata = EntityMetadata({
      name: "name",
      dappURL: "dappURL",
      description: "description"
    });

    world.call(
      characterSystemId,
      abi.encodeCall(
        SmartCharacterSystem.createCharacter,
        (567, ephemeralInvOwner1, tribeId, entityRecord, entityRecordMetadata)
      )
    );

    world.call(
      characterSystemId,
      abi.encodeCall(
        SmartCharacterSystem.createCharacter,
        (897, ephemeralInvOwner2, tribeId, entityRecord, entityRecordMetadata)
      )
    );

    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00001")));
    InventoryItem[] memory items = new InventoryItem[](2);
    items[0] = InventoryItem({
      inventoryItemId: 456,
      owner: ephemeralInvOwner1,
      itemId: 22,
      typeId: 3,
      volume: 10,
      quantity: 3
    });

    items[1] = InventoryItem({
      inventoryItemId: 789,
      owner: ephemeralInvOwner1,
      itemId: 0,
      typeId: 34,
      volume: 10,
      quantity: 10
    });

    world.call(
      ephemeralSystemId,
      abi.encodeCall(
        EphemeralInventorySystem.createAndDepositItemsToEphemeralInventory,
        (smartObjectId, ephemeralInvOwner1, items)
      )
    );

    items = new InventoryItem[](1);
    items[0] = InventoryItem({
      inventoryItemId: 888,
      owner: ephemeralInvOwner2,
      itemId: 0,
      typeId: 35,
      volume: 10,
      quantity: 300
    });

    world.call(
      ephemeralSystemId,
      abi.encodeCall(
        EphemeralInventorySystem.createAndDepositItemsToEphemeralInventory,
        (smartObjectId, ephemeralInvOwner2, items)
      )
    );

    vm.stopBroadcast();
  }
}
