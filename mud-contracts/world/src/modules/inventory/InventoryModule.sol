//SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { Module } from "@latticexyz/world/src/Module.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { INVENTORY_MODULE_NAME as MODULE_NAME, INVENTORY_MODULE_NAMESPACE as MODULE_NAMESPACE } from "./constants.sol";
import { InventoryTable } from "../../codegen/tables/InventoryTable.sol";
import { InventoryItemTable } from "../../codegen/tables/InventoryItemTable.sol";
import { EphemeralInvTable } from "../../codegen/tables/EphemeralInvTable.sol";
import { EphemeralInvItemTable } from "../../codegen/tables/EphemeralInvItemTable.sol";
import { ItemTransferOffchainTable } from "../../codegen/tables/ItemTransferOffchainTable.sol";

import { InventorySystem } from "./systems/InventorySystem.sol";
import { EphemeralInventorySystem } from "./systems/EphemeralInventorySystem.sol";

import { Utils } from "./Utils.sol";

contract InventoryModule is Module {
  error InventoryModule_InvalidNamespace(bytes14 namespace);

  address immutable registrationLibrary = address(new InventoryModuleRegistrationLibrary());

  function getName() public pure returns (bytes16) {
    return MODULE_NAME;
  }

  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _requireDependencies() internal view {
    //Require other dependant modules to be registered
  }

  // TODO: right now it needs to receive each system address as parameters (because of contract size limit), but there is no type checking
  // fix it
  function install(bytes memory encodeArgs) public {
    //Require the module to be installed with the args
    requireNotInstalled(__self, encodeArgs);

    //Extract args
    (bytes14 namespace, address inventorySystem, address ephemeralInventory, address inventoryInteract) = abi.decode(
      encodeArgs,
      (bytes14, address, address, address)
    );

    //Require the namespace to not be the module's namespace
    if (namespace == MODULE_NAMESPACE) {
      revert InventoryModule_InvalidNamespace(namespace);
    }

    //Require the dependencies to be installed
    _requireDependencies();

    //Register Inventory module's tables and systems
    IBaseWorld world = IBaseWorld(_world());
    (bool success, bytes memory returnedData) = registrationLibrary.delegatecall(
      abi.encodeCall(
        InventoryModuleRegistrationLibrary.register,
        (world, namespace, inventorySystem, ephemeralInventory, inventoryInteract)
      )
    );
    if (!success) revertWithBytes(returnedData);

    //Transfer the ownership of the namespace to the caller
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    world.transferOwnership(namespaceId, _msgSender());
  }

  function installRoot(bytes memory) public pure {
    revert Module_RootInstallNotSupported();
  }
}

contract InventoryModuleRegistrationLibrary {
  using Utils for bytes14;

  function register(
    IBaseWorld world,
    bytes14 namespace,
    address inventorySystem,
    address ephemeralInventory,
    address inventoryInteract
  ) public {
    //Register the namespace
    if (!ResourceIds.getExists(WorldResourceIdLib.encodeNamespace(namespace)))
      world.registerNamespace(WorldResourceIdLib.encodeNamespace(namespace));

    //Register the tables and systems for inventory namespace
    if (!ResourceIds.getExists(InventoryTable._tableId)) InventoryTable.register();
    if (!ResourceIds.getExists(InventoryItemTable._tableId)) InventoryItemTable.register();
    if (!ResourceIds.getExists(EphemeralInvTable._tableId)) EphemeralInvTable.register();
    if (!ResourceIds.getExists(EphemeralInvTable._tableId)) EphemeralInvTable.register();
    if (!ResourceIds.getExists(EphemeralInvItemTable._tableId)) EphemeralInvItemTable.register();
    if (!ResourceIds.getExists(ItemTransferOffchainTable._tableId)) ItemTransferOffchainTable.register();

    //Register the systems
    if (!ResourceIds.getExists(namespace.inventorySystemId()))
      world.registerSystem(namespace.inventorySystemId(), System(inventorySystem), true);
    if (!ResourceIds.getExists(namespace.ephemeralInventorySystemId()))
      world.registerSystem(namespace.ephemeralInventorySystemId(), System(ephemeralInventory), true);
    if (!ResourceIds.getExists(namespace.inventoryInteractSystemId()))
      world.registerSystem(namespace.inventoryInteractSystemId(), System(inventoryInteract), true);
  }
}
