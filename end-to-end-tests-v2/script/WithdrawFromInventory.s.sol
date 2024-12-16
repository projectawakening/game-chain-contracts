pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { InventoryItem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { InventoryUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/InventoryUtils.sol";
import { InventorySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/InventorySystem.sol";
import { InventoryItemData, InventoryItem as InventoryItemTable } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/InventoryItem.sol";

contract WithdrawFromInventory is Script {
  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address invOwner = vm.addr(deployerPrivateKey);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);
    ResourceId inventorySystemId = InventoryUtils.inventorySystemId();

    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00001")));
    InventoryItem[] memory items = new InventoryItem[](3);
    items[0] = InventoryItem({ inventoryItemId: 123, owner: invOwner, itemId: 0, typeId: 23, volume: 10, quantity: 1 });
    items[1] = InventoryItem({
      inventoryItemId: 1234,
      owner: invOwner,
      itemId: 0,
      typeId: 34,
      volume: 10,
      quantity: 10
    });
    items[2] = InventoryItem({
      inventoryItemId: 1235,
      owner: invOwner,
      itemId: 0,
      typeId: 35,
      volume: 10,
      quantity: 10
    });

    world.call(inventorySystemId, abi.encodeCall(InventorySystem.withdrawFromInventory, (smartObjectId, items)));

    InventoryItemData memory inventoryItem1 = InventoryItemTable.get(smartObjectId, items[0].inventoryItemId);
    InventoryItemData memory inventoryItem2 = InventoryItemTable.get(smartObjectId, items[1].inventoryItemId);

    console.log(inventoryItem1.quantity);
    InventoryItemData memory inventoryItem3 = InventoryItemTable.get(smartObjectId, items[2].inventoryItemId);

    console.log(inventoryItem1.quantity);
    console.log(inventoryItem2.quantity);
    console.log(inventoryItem3.quantity);

    vm.stopBroadcast();
  }
}
