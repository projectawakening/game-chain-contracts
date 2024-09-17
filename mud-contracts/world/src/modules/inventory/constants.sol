// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_NAMESPACE } from "@latticexyz/world/src/worldResourceTypes.sol";

bytes16 constant INVENTORY_MODULE_NAME = "InventoryModule";
bytes14 constant INVENTORY_MODULE_NAMESPACE = "InvModule";

ResourceId constant INVENTORY_NAMESPACE_ID = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_NAMESPACE, INVENTORY_MODULE_NAMESPACE))
);

bytes16 constant INVENTORY_SYSTEM_NAME = "InventorySystem";
bytes16 constant EPHEMERAL_INVENTORY_SYSTEM_NAME = "EphemeralInvSyst";
bytes16 constant INVENTORY_INTERACT_SYSTEM_NAME = "InventoryInterac";

bytes16 constant INVENTORY_TABLE_NAME = "InventoryTable";
bytes16 constant INVENTORY_ITEM_TABLE_NAME = "InventoryItemTab";
bytes16 constant EPHEMERAL_INVENTORY_TABLE_NAME = "EphemeralInvTabl";
bytes16 constant EPHEMERAL_INVENTORY_CAPACITY_TABLE_NAME = "EphemeralInvCapa";
bytes16 constant EPHEMERAL_INVENTORY_ITEM_TABLE_NAME = "EphemeralInvItem";
bytes16 constant ITEM_TRANSFER_TABLE_NAME = "ItemTransferOffc";
