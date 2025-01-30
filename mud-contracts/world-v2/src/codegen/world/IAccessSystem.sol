// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title IAccessSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IAccessSystem {
  error Access_NotAdmin(address caller);
  error Access_NotDeployableOwner(address caller, uint256 objectId);
  error Access_NotAdminOrOwner(address caller, uint256 objectId);
  error Access_NotOwnerOrCanWithdrawFromInventory(address caller, uint256 objectId);
  error Access_NotOwnerOrCanDepositToInventory(address caller, uint256 objectId);
  error Access_NotDeployableOwnerOrInventoryInteractSystem(address caller, uint256 objectId);
  error Access_NotInventoryAdmin(address caller, uint256 smartObjectId);

  function evefrontier__onlyOwnerOrCanWithdrawFromInventory(uint256 objectId, bytes memory data) external view;

  function evefrontier__onlyOwnerOrCanDepositToInventory(uint256 objectId, bytes memory data) external view;

  function evefrontier__onlyDeployableOwner(uint256 objectId, bytes memory data) external view;

  function evefrontier__onlyAdmin(uint256 objectId, bytes memory data) external view;

  function evefrontier__onlyAdminOrDeployableOwner(uint256 objectId, bytes memory data) external view;

  function evefrontier__onlyDeployableOwnerOrInventoryInteractSystem(uint256 objectId, bytes memory data) external view;

  function evefrontier__onlyInventoryAdmin(uint256 smartObjectId, bytes memory data) external view;

  function evefrontier__isAdmin(address caller) external view returns (bool);

  function evefrontier__isOwner(address caller, uint256 objectId) external view returns (bool);

  function evefrontier__canWithdrawFromInventory(uint256 smartObjectId, address caller) external view returns (bool);

  function evefrontier__canDepositToInventory(uint256 smartObjectId, address caller) external view returns (bool);

  function evefrontier__isInventoryInteractSystem(address caller) external view returns (bool);

  function evefrontier__isInventoryAdmin(uint256 smartObjectId, address caller) external view returns (bool);
}
