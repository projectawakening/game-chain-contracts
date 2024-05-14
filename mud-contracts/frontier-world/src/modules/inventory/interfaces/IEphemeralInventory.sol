// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

import { InventoryItem } from "../types.sol";

/**
 * @title IEphemeralInventory
 * @dev This interface is to make interacting with the underlying system easier via worldCall.
 */
interface IEphemeralInventory {
  function setEphemeralInventoryCapacity(uint256 smartObjectId, uint256 ephemeralStorageCapacity) external;

  function depositToEphemeralInventory(uint256 smartObjectId, address owner, InventoryItem[] memory items) external;

  function withdrawFromEphemeralInventory(uint256 smartObjectId, address owner, InventoryItem[] memory items) external;

  function invalidateEphemeralItems(uint256 smartObjectId) external;
}
