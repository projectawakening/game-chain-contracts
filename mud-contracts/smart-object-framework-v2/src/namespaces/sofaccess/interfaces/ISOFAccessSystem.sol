// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ISOFAccessSystem
 * @dev An interface for the SOF access control logic functionality
 */
interface ISOFAccessSystem {
  // EntitySystem.sol access
  function allowClassAccessRole(uint256 classId, bytes memory targetCallData) external view;
  function allowClassScopedSystemOrDirectClassAccessRole(uint256 entityId, bytes memory targetCallData) external view;
  function allowClassScopedSystemOrDirectObjectAccessRole(uint256 objectId, bytes memory targetCallData) external view;
  // TagSystem.sol access
  function allowEntitySystemOrDirectAccessRole(uint256 entityId, bytes memory targetCallData) external view;

  error SOFAccess_RoleAccessDenied(bytes32 accessRole, address account);
  error SOFAccess_SystemAccessDenied(uint256 entityId, address systemAddress);
  error SOFAccess_DirectCall();
}
