pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { InventoryItem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { EphemeralInventorySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/EphemeralInventorySystem.sol";
import { EphemeralInvItem, EphemeralInvItemData } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/EphemeralInvItem.sol";
import { TransferItem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { InventoryItemData, InventoryItem as InventoryItemTable } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/InventoryItem.sol";
import { InventoryInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/InventoryInteractSystem.sol";

import { inventoryInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/InventoryInteractSystemLib.sol";

contract TransferItems is Script {
  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address invOwner = vm.addr(deployerPrivateKey);

    string memory mnemonic = "test test test test test test test test test test test junk";
    uint256 alice = vm.deriveKey(mnemonic, 2);
    address ephemeralInvOwner1 = vm.addr(alice);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);
    ResourceId invInteractSystemId = inventoryInteractSystem.toResourceId();

    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00001")));

    // ITEM TO MOVE FROM INVENTORY TO EPHEMERAL
    uint256 itemId = 1235;
    TransferItem[] memory invTransferItems = new TransferItem[](1);
    invTransferItems[0] = TransferItem(itemId, invOwner, 1);

    // ITEM TO MOVE FROM EPHEMERAL TO INVENTORY
    uint256 ephItemId = 789;
    TransferItem[] memory ephInvTransferItems = new TransferItem[](1);
    ephInvTransferItems[0] = TransferItem(ephItemId, ephemeralInvOwner1, 1);

    // TRANSFER
    inventoryInteractSystem.inventoryToEphemeralTransfer(smartObjectId, ephemeralInvOwner1, invTransferItems);
    inventoryInteractSystem.ephemeralToInventoryTransfer(smartObjectId, ephemeralInvOwner1, ephInvTransferItems);

    // After transfer 1 invItem should go into ephemeral and 1 ephInvItem should go into inventory
    // SSU owner should have 1 ephInvItem after transfer
    // Ephermeral owner should have 1 invItem after transfer

    EphemeralInvItemData memory ephItemInInv = EphemeralInvItem.get(
      smartObjectId,
      ephInvTransferItems[0].inventoryItemId,
      ephemeralInvOwner1
    );
    console.log(ephItemInInv.quantity); //1

    InventoryItemData memory invItem = InventoryItemTable.get(smartObjectId, invTransferItems[0].inventoryItemId);
    console.log(invItem.quantity); //1

    // STOP THE BROADCAST
    vm.stopBroadcast();
  }
}
