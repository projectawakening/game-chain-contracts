pragma solidity >=0.8.20;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceAccess } from "@latticexyz/world/src/codegen/tables/ResourceAccess.sol";
import { RESOURCE_SYSTEM, RESOURCE_TABLE } from "@latticexyz/world/src/worldResourceTypes.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { Utils as InventoryUtils } from "../src/modules/inventory/Utils.sol";
import { Utils as SmartStorageUnitUtils } from "../src/modules/smart-storage-unit/Utils.sol";
import { IInventory } from "../src/modules/inventory/interfaces/IInventory.sol";
import { IEphemeralInventory } from "../src/modules/inventory/interfaces/IEphemeralInventory.sol";
import { ISmartStorageUnit } from "../src/modules/smart-storage-unit/interfaces/ISmartStorageUnit.sol";


// not included in the @eveworld package yet, so include here for the time being
interface IAccess {
  function setAccessListByRole(bytes32 accessRoleId, address[] memory accessList) external;
  function setAccessEnforcement(bytes32 target, bool isEnforced) external;
}

// NOTE: ASSUMES YOU HAVE APPLIED ACCESS-CONTROL UPDATES TO THE EVE WORLD
contract InventoryAccess is Script {
  using InventoryUtils for bytes14;
  using SmartStorageUnitUtils for bytes14;

  bytes14 constant EVE_WORLD_NAMESPACE = bytes14("eveworld");
  bytes16 constant ACCESS_SYSTEM_NAME = "AccessSystem";
  ResourceId ACCESS_SYSTEM_ID = WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: EVE_WORLD_NAMESPACE, name: ACCESS_SYSTEM_NAME });
  
  bytes16 constant ACCESS_ROLE_TABLE_NAME = "AccessRole";
  ResourceId ACCESS_ROLE_TABLE_ID = WorldResourceIdLib.encode({ typeId: RESOURCE_TABLE, namespace: EVE_WORLD_NAMESPACE, name: ACCESS_ROLE_TABLE_NAME });

  // AccessRole constants
  bytes32 constant ADMIN = bytes32("ADMIN_ACCESS_ROLE");
  bytes32 constant APPROVED = bytes32("APPROVED_ACCESS_ROLE");

  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    
    address[] memory adminAccounts = vm.envAddress("ADMIN_ACCOUNTS", ",");
    // must populate this with ALL active ADMIN public addresses (to prevent any transaction failures)
    address[] memory adminAccessList = new address[](adminAccounts.length);
    
    for (uint i = 0; i < adminAccounts.length; i++) {
      adminAccessList[i] = adminAccounts[i];
    }

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);

    // assumes AccessRole has been deployed into the eveworld namespace, and the current privkey is the eveworld namespace owner
    // if no access, grant self access to this resource allowing for Access configuration access
    if(!ResourceAccess.get(ACCESS_ROLE_TABLE_ID, deployer)) {
      world.grantAccess(ACCESS_ROLE_TABLE_ID, deployer);
    }

    address[] memory approvedAccessList = new address[](1);
    // currently we are only allowing InventoryInteract to be an APPROVED call forwarder
    address interactAddr = Systems.getSystem(EVE_WORLD_NAMESPACE.inventoryInteractSystemId());
    approvedAccessList[0] = interactAddr;
    // set access ADMIN accounts
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessListByRole, (ADMIN, adminAccessList)));
    // set access APPROVED account
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessListByRole, (APPROVED, approvedAccessList)));

    // target functions to set access control enforcement for
    // Inventory.depositToInventory
    bytes32 invDeposit = keccak256(abi.encodePacked(EVE_WORLD_NAMESPACE.inventorySystemId(), IInventory.depositToInventory.selector));
    // Inventory.withdrawalFromInventory
    bytes32 invWithdraw = keccak256(abi.encodePacked(EVE_WORLD_NAMESPACE.inventorySystemId(), IInventory.withdrawFromInventory.selector));
    // EphemeralInventory.depositToEphemeralInventory
    bytes32 ephInvDeposit = keccak256(abi.encodePacked(EVE_WORLD_NAMESPACE.ephemeralInventorySystemId(), IEphemeralInventory.depositToEphemeralInventory.selector));
    // EphemeralInventory.withdrawalFromEphemeralInventory
    bytes32 ephInvWithdraw = keccak256(abi.encodePacked(EVE_WORLD_NAMESPACE.ephemeralInventorySystemId(), IEphemeralInventory.withdrawFromEphemeralInventory.selector));
    // SmartStorageUnit.createAndDepositItemsToInventory
    bytes32 invCreateAndDeposit = keccak256(abi.encodePacked(EVE_WORLD_NAMESPACE.smartStorageUnitSystemId(), ISmartStorageUnit.createAndDepositItemsToInventory.selector));
    // SmartStorageUnit.createAndDepositItemsToEphemeralInventory
    bytes32 ephInvCreateAndDeposit = keccak256(abi.encodePacked(EVE_WORLD_NAMESPACE.smartStorageUnitSystemId(), ISmartStorageUnit.createAndDepositItemsToEphemeralInventory.selector));

    // set enforcement to true for all
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessEnforcement, (invDeposit, true)));
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessEnforcement, (invWithdraw, true)));
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessEnforcement, (ephInvDeposit, true)));
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessEnforcement, (ephInvWithdraw, true)));
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessEnforcement, (invCreateAndDeposit, true)));
    world.call(ACCESS_SYSTEM_ID, abi.encodeCall(IAccess.setAccessEnforcement, (ephInvCreateAndDeposit, true)));

    vm.stopBroadcast();
  }
}