// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/**
 * @title ISOFAccessSystem
 * @dev An interface for the SOF access control logic functionality
 */
interface ISOFAccessSystem {
  // EntitySystem.sol access
  function allowDirectAccessRole(uint256 entityId, bytes memory targetCallData) external view;
  function allowDirectClassAccessRole(uint256 entityId, bytes memory targetCallData) external view;
  function allowClassScopedSystemOrDirectClassAccessRole(uint256 entityId, bytes memory targetCallData) external view;
  function allowClassScopedSystemOrDirectAccessRole(uint256 entityId, bytes memory targetCallData) external view;
  function allowDefinedSystems(uint256 entityId, bytes memory targetCallData) external view;
  // TagSystem.sol access
  function allowEntitySystemOrDirectAccessRole(uint256 entityId, bytes memory targetCallData) external view;
  // RoleManagerSystem.sol access
  function allowEntitySystemOrClassScopedSystem(uint256 entityId, bytes memory targetCallData) external view;
  function allowClassScopedSystem(uint256 entityId, bytes memory targetCallData) external view;

  error SOFAccess_AccessDenied(uint256 entityId, address caller);
}
