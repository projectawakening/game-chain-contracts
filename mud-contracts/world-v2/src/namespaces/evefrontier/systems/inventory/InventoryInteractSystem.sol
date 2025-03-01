// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";

import { InventorySystem } from "./InventorySystem.sol";
import { EphemeralInventorySystem } from "./EphemeralInventorySystem.sol";
import { IERC721 } from "../eve-erc721-puppet/IERC721.sol";
import { DeployableToken } from "../../codegen/index.sol";
import { EntityRecord, EntityRecordData } from "../../codegen/index.sol";
import { InventoryItemData, InventoryItem as InventoryItemTable } from "../../codegen/index.sol";
import { ItemTransferOffchain } from "../../codegen/index.sol";
import { EphemeralInvItem } from "../../codegen/index.sol";
import { InventoryUtils } from "./InventoryUtils.sol";
import { TransferItem, InventoryItem } from "./types.sol";

import { InventorySystemLib, inventorySystem } from "../../codegen/systems/InventorySystemLib.sol";
import { EphemeralInventorySystemLib, ephemeralInventorySystem } from "../../codegen/systems/EphemeralInventorySystemLib.sol";
import { roleManagementSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/RoleManagementSystemLib.sol";

/**
 * @title InventoryInteractSystem
 * @author CCP Games
 * @notice This system is responsible for the interaction between the inventory and ephemeral inventory
 * @dev This system is responsible for the interaction between the inventory and ephemeral inventory
 */

contract InventoryInteractSystem is SmartObjectFramework {
  error Inventory_InvalidTransferItemQuantity(
    string message,
    uint256 smartObjectId,
    string inventoryType,
    address inventoryOwner,
    uint256 inventoryItemId,
    uint256 quantity
  );

  /**
   * @notice Transfer items from ephemeral to inventory
   * @dev transfer items from ephemeral to inventory
   * @param smartObjectId is the smart object id
   * @param ephInvOwner is the ephemeral inventory owner
   * @param items is the array of items to transfer
   * TODO: get the _initialMsgSender when execution context is implemented
   * TODO: add scope modifier back to this function. it was not used due to stack too deep compiler error.
   */
  function ephemeralToInventoryTransfer(
    uint256 smartObjectId,
    address ephInvOwner,
    TransferItem[] memory items
  ) public context access(smartObjectId) scope(smartObjectId) {
    InventoryItem[] memory ephInvOut = new InventoryItem[](items.length);
    InventoryItem[] memory invIn = new InventoryItem[](items.length);
    // address ephInvOwner = _initialMsgSender();
    address objectInvOwner = IERC721(DeployableToken.getErc721Address()).ownerOf(smartObjectId);
    for (uint i = 0; i < items.length; i++) {
      TransferItem memory item = items[i];
      //check the ephInvOwner has enough items to transfer to the inventory
      if (EphemeralInvItem.get(smartObjectId, item.inventoryItemId, ephInvOwner).quantity < item.quantity) {
        revert Inventory_InvalidTransferItemQuantity(
          "InventoryInteractSystem: not enough items to transfer",
          smartObjectId,
          "EPHEMERAL",
          ephInvOwner,
          item.inventoryItemId,
          item.quantity
        );
      }
      EntityRecordData memory itemRecord = EntityRecord.get(item.inventoryItemId);

      ephInvOut[i] = InventoryItem({
        inventoryItemId: item.inventoryItemId,
        owner: ephInvOwner,
        itemId: itemRecord.itemId,
        typeId: itemRecord.typeId,
        volume: itemRecord.volume,
        quantity: item.quantity
      });

      //Emitting the event before the transfer to reduce loop execution, might need to consider security implications later
      ItemTransferOffchain.set(
        smartObjectId,
        item.inventoryItemId,
        ephInvOwner,
        objectInvOwner,
        item.quantity,
        block.timestamp
      );
    }

    // withdraw the items from ephemeral and deposit to inventory table
    ephemeralInventorySystem.withdrawFromEphemeralInventory(smartObjectId, ephInvOwner, ephInvOut);

    for (uint i = 0; i < items.length; i++) {
      invIn[i] = ephInvOut[i];
      invIn[i].owner = objectInvOwner;
    }

    inventorySystem.depositToInventory(smartObjectId, invIn);
  }

  function setEphemeralToInventoryTransferAccess(
    uint256 smartObjectId,
    address accessAddress,
    bool isAllowed
  ) public context access(smartObjectId) scope(smartObjectId) {
    bytes32 accessRole = InventoryUtils.getEphemeralToInventoryTransferAccessRole(smartObjectId);

    if (isAllowed) {
      roleManagementSystem.grantRole(accessRole, accessAddress);
    } else {
      roleManagementSystem.revokeRole(accessRole, accessAddress);
    }
  }

  function setInventoryToEphemeralTransferAccess(
    uint256 smartObjectId,
    address accessAddress,
    bool isAllowed
  ) public context access(smartObjectId) scope(smartObjectId) {
    bytes32 accessRole = InventoryUtils.getInventoryToEphemeralTransferAccessRole(smartObjectId);

    if (isAllowed) {
      roleManagementSystem.grantRole(accessRole, accessAddress);
    } else {
      roleManagementSystem.revokeRole(accessRole, accessAddress);
    }
  }

  function setInventoryAdminAccess(
    uint256 smartObjectId,
    address accessAddress,
    bool isAllowed
  ) public context access(smartObjectId) scope(smartObjectId) {
    bytes32 adminAccessRole = InventoryUtils.getAdminAccessRole(smartObjectId);
    if (isAllowed) {
      roleManagementSystem.grantRole(adminAccessRole, accessAddress);
    } else {
      roleManagementSystem.revokeRole(adminAccessRole, accessAddress);
    }
  }

  /**
   * @notice Transfer items from inventory to ephemeral
   * @dev transfer items from inventory storage to an ephemeral storage
   * @param smartObjectId is the smart object id
   * @param ephemeralInventoryOwner is the ephemeral inventory owner
   * @param items is the array of items to transfer
   * TODO: add scope modifier back to this function. it was not used due to stack too deep compiler error.
   */
  function inventoryToEphemeralTransfer(
    uint256 smartObjectId,
    address ephemeralInventoryOwner,
    TransferItem[] memory items
  ) public context access(smartObjectId) scope(smartObjectId) {
    InventoryItem[] memory invOut = new InventoryItem[](items.length);
    InventoryItem[] memory ephInvIn = new InventoryItem[](items.length);
    address objectInvOwner = IERC721(DeployableToken.getErc721Address()).ownerOf(smartObjectId);

    for (uint i = 0; i < items.length; i++) {
      TransferItem memory item = items[i];
      if (InventoryItemTable.get(smartObjectId, item.inventoryItemId).quantity < item.quantity) {
        revert Inventory_InvalidTransferItemQuantity(
          "InventoryInteractSystem: not enough items to transfer",
          smartObjectId,
          "OBJECT",
          objectInvOwner,
          item.inventoryItemId,
          item.quantity
        );
      }

      EntityRecordData memory itemRecord = EntityRecord.get(item.inventoryItemId);

      invOut[i] = InventoryItem({
        inventoryItemId: item.inventoryItemId,
        owner: objectInvOwner,
        itemId: itemRecord.itemId,
        typeId: itemRecord.typeId,
        volume: itemRecord.volume,
        quantity: item.quantity
      });

      //Emitting the event before the transfer to reduce loop execution, might need to consider security implications later
      ItemTransferOffchain.set(
        smartObjectId,
        item.inventoryItemId,
        objectInvOwner,
        ephemeralInventoryOwner,
        item.quantity,
        block.timestamp
      );
    }

    //withdraw the items from inventory and deposit to ephemeral inventory
    inventorySystem.withdrawFromInventory(smartObjectId, invOut);

    for (uint i = 0; i < items.length; i++) {
      ephInvIn[i] = invOut[i];
      ephInvIn[i].owner = ephemeralInventoryOwner;
    }

    ephemeralInventorySystem.depositToEphemeralInventory(smartObjectId, ephemeralInventoryOwner, ephInvIn);
  }
}
