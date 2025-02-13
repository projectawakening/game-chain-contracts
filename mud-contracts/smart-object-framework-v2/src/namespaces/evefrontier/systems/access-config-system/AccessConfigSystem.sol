// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { AccessConfig } from "../../codegen/tables/AccessConfig.sol";
import { Role } from "../../codegen/tables/Role.sol";

import { IAccessConfigSystem } from "../../interfaces/IAccessConfigSystem.sol";
import { IWorldWithContext } from "../../../../IWorldWithContext.sol";

import { SmartObjectFramework } from "../../../../inherit/SmartObjectFramework.sol";

/**
 * @title AccessConfigSystem
 * @author CCP Games
 * @dev Manage access logic configuration and enforcement for any world registered System/function target
 */
contract AccessConfigSystem is IAccessConfigSystem, SmartObjectFramework {
  using WorldResourceIdInstance for ResourceId;

  function configureAccess(
    ResourceId targetSystemId,
    bytes4 targetFunctionId,
    ResourceId accessSystemId,
    bytes4 accessFunctionId
  ) public context enforceCallCount(1) {
    // check if target system is registered
    if (!ResourceIds.getExists(targetSystemId)) {
      revert AccessConfig_InvalidTargetSystem(targetSystemId);
    }

    // check if access system is registered
    if (!ResourceIds.getExists(accessSystemId)) {
      revert AccessConfig_InvalidAccessSystem(accessSystemId);
    }

    // check access by namespace ownership (the entry point msg.sender should be the namespace owner of the target system)
    if (NamespaceOwner.getOwner(targetSystemId.getNamespaceId()) != _callMsgSender(1)) {
      revert AccessConfig_AccessDenied(targetSystemId, _callMsgSender(1));
    }

    bytes32 target = keccak256(abi.encodePacked(targetSystemId, targetFunctionId));

    AccessConfig.set(target, true, targetSystemId, targetFunctionId, accessSystemId, accessFunctionId, false);
  }

  function setAccessEnforcement(
    ResourceId targetSystemId,
    bytes4 targetFunctionId,
    bool enforced
  ) public context enforceCallCount(1) {
    // check access by namespace ownership (the entry point msg.sender should be the namespace owner of the target system)
    if (NamespaceOwner.getOwner(targetSystemId.getNamespaceId()) != _callMsgSender(1)) {
      revert AccessConfig_AccessDenied(targetSystemId, _callMsgSender(1));
    }

    bytes32 target = keccak256(abi.encodePacked(targetSystemId, targetFunctionId));

    // check if target is configured
    if (!AccessConfig.getConfigured(target)) {
      revert AccessConfig_TargetNotConfigured(targetSystemId, targetFunctionId);
    }

    AccessConfig.setEnforcement(target, enforced);
  }
}
