// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title IAdminAccessSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IAdminAccessSystem {
  error AdminAccess_NotAdmin(address caller);

  function evefrontier__onlyAdmin(uint256 objectId, bytes memory data) external view;
}
