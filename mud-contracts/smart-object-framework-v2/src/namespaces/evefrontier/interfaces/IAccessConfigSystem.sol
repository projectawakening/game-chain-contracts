// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Id } from "../../../libs/Id.sol";

/**
 * @title IAccessConfigSystem
 * @dev An interface for the Access Configuration System functionality
 */
interface IAccessConfigSystem {
  function configureAccess(
    ResourceId targetSystemId,
    bytes4 targetFunctionId,
    ResourceId accessSystemId,
    bytes4 accessFunctionId
  ) external;
  function setAccessEnforcement(ResourceId targetSystemId, bytes4 targetFunctionId, bool enforced) external;

  error AccessConfig_AccessDenied(ResourceId targetSystemId, address caller);
  error AccessConfig_RoleAccessDenied(bytes32 roleId, address caller);
  error AccessConfig_InvalidTargetSystem(ResourceId targetSystemId);
  error AccessConfig_InvalidAccessSystem(ResourceId accessSystemId);
  error AccessConfig_TargetNotConfigured(ResourceId targetSystemId, bytes4 targetFunctionId);
}
