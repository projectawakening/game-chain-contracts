// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { HasRole } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/index.sol";
import { DeployableToken } from "../../codegen/index.sol";
import { IERC721 } from "../eve-erc721-puppet/IERC721.sol";
import { InventoryUtils } from "../inventory/InventoryUtils.sol";

contract AccessSystem is SmartObjectFramework {
  error Access_NotAdmin(address caller);
  error Access_NotOwner(address caller, uint256 objectId);
  error Access_NotAdminOrOwner(address caller, uint256 objectId);

  error Access_NotOwnerOrCanWithdrawFromInventory(address caller, uint256 objectId);
  error Access_NotOwnerOrCanDepositToInventory(address caller, uint256 objectId);
  error Access_NotDeployableOwnerOrInventoryInteractSystem(address caller, uint256 objectId);
  error Access_NotInventoryAdmin(address caller, uint256 smartObjectId);

  function onlyOwnerOrCanWithdrawFromInventory(uint256 objectId, bytes memory data) public view {
    if (!isOwner(_callMsgSender(1), objectId) && !canWithdrawFromInventory(objectId, _callMsgSender(1))) {
      revert Access_NotOwnerOrCanWithdrawFromInventory(_callMsgSender(1), objectId);
    }
  }

  function onlyOwnerOrCanDepositToInventory(uint256 objectId, bytes memory data) public view {
    if (!isOwner(_callMsgSender(1), objectId) && !canDepositToInventory(objectId, _callMsgSender(1))) {
      revert Access_NotOwnerOrCanDepositToInventory(_callMsgSender(1), objectId);
    }
  }

  function onlyDeployableOwner(uint256 objectId, bytes memory data) public view {
    if (!isOwner(_callMsgSender(1), objectId)) {
      revert Access_NotOwner(_callMsgSender(1), objectId);
    }
  }

  function onlyAdmin(uint256 objectId, bytes memory data) public view {
    if (!isAdmin(_callMsgSender(1))) {
      revert Access_NotAdmin(_callMsgSender(1));
    }
  }

  function onlyAdminOrDeployableOwner(uint256 objectId, bytes memory data) public view {
    if (!isAdmin(_callMsgSender(1)) && !isOwner(_callMsgSender(1), objectId)) {
      revert Access_NotAdminOrOwner(_callMsgSender(1), objectId);
    }
  }

  function onlyDeployableOwner(uint256 objectId, bytes memory data) public view {
    if (!isOwner(_callMsgSender(1), objectId)) {
      revert Access_NotDeployableOwner(_callMsgSender(1), objectId);
    }
  }

  function onlyDeployableOwnerOrInventoryInteractSystem(uint256 objectId, bytes memory data) public view {
    if (!isOwner(_callMsgSender(1), objectId) && !isInventoryInteractSystem(_callMsgSender(1))) {
      revert Access_NotDeployableOwnerOrInventoryInteractSystem(_callMsgSender(1), objectId);
    }
  }

  function onlyInventoryAdmin(uint256 smartObjectId, bytes memory data) public view {
    if (!isInventoryAdmin(smartObjectId, _callMsgSender(1))) {
      revert Access_NotInventoryAdmin(_callMsgSender(1), smartObjectId);
    }
  }

  function isAdmin(address caller) public view returns (bool) {
    return HasRole.getHasRole("admin", caller);
  }

  function isOwner(address caller, uint256 objectId) public view returns (bool) {
    address erc721Address = DeployableToken.getErc721Address();
    address owner = IERC721(erc721Address).ownerOf(objectId);
    return owner == caller;
  }

  function canWithdrawFromInventory(uint256 smartObjectId, address caller) public view returns (bool) {
    bytes32 accessRole = InventoryUtils.getInventoryToEphemeralTransferAccessRole(smartObjectId);
    return HasRole.getHasRole(accessRole, caller);
  }

  function canDepositToInventory(uint256 smartObjectId, address caller) public view returns (bool) {
    bytes32 accessRole = InventoryUtils.getEphemeralToInventoryTransferAccessRole(smartObjectId);
    return HasRole.getHasRole(accessRole, caller);
  }

  function isInventoryInteractSystem(address caller) public view returns (bool) {
    return caller == address(inventoryInteractSystem);
  }

  function isInventoryAdmin(uint256 smartObjectId, address caller) public view returns (bool) {
    bytes32 adminAccessRole = InventoryUtils.getAdminAccessRole(smartObjectId);
    return HasRole.getHasRole(adminAccessRole, caller);
  }
}
