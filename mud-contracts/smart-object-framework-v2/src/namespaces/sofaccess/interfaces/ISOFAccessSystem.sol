// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Id } from "../../../libs/Id.sol";

/**
 * @title ISOFAccessSystem
 * @dev An interface for the SOF access control logic functionality
 */
interface ISOFAccessSystem {
  // EntitySystem.sol access
  function allowClassAccessRole(Id classId, bytes memory targetCallData) external view;
  function allowClassScopedSystemOrDirectClassAccessRole(Id entityId, bytes memory targetCallData) external view;
  function allowClassScopedSystemOrDirectObjectAccessRole(Id objectId, bytes memory targetCallData) external view;
  // TagSystem.sol access
  function allowEntitySystemOrDirectAccessRole(Id entityId, bytes memory targetCallData) external view;

  error SOFAccess_RoleAccessDenied(bytes32 accessRole, address account);
  error SOFAccess_SystemAccessDenied(Id entityId, address systemAddress);
  error SOFAccess_DirectCall();
}
