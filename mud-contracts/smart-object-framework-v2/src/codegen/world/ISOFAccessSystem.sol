// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title ISOFAccessSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ISOFAccessSystem {
  function sofaccess__allowDirectAccessRole(uint256 entityId, bytes memory targetCallData) external view;

  function sofaccess__allowDirectClassAccessRole(uint256 entityId, bytes memory targetCallData) external view;

  function sofaccess__allowClassScopedSystem(uint256 entityId, bytes memory targetCallData) external view;

  function sofaccess__allowClassScopedSystemOrDirectClassAccessRole(
    uint256 entityId,
    bytes memory targetCallData
  ) external view;

  function sofaccess__allowClassScopedSystemOrDirectAccessRole(
    uint256 entityId,
    bytes memory targetCallData
  ) external view;

  function sofaccess__allowEntitySystemOrDirectAccessRole(uint256 entityId, bytes memory targetCallData) external view;

  function sofaccess__allowEntitySystemOrClassScopedSystem(uint256 entityId, bytes memory targetCallData) external view;

  function sofaccess__allowDefinedSystems(uint256 entityId, bytes memory targetCallData) external view;
}
