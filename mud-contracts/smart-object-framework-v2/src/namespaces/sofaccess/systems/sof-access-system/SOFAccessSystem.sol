// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";

import { Entity } from "../../../evefrontier/codegen/tables/Entity.sol";
import { EntityTagMap } from "../../../evefrontier/codegen/tables/EntityTagMap.sol";

import { Role } from "../../../evefrontier/codegen/tables/Role.sol";
import { HasRole } from "../../../evefrontier/codegen/tables/HasRole.sol";

import { TagId, TagIdLib } from "../../../../libs/TagId.sol";

import { TAG_TYPE_PROPERTY, TAG_TYPE_ENTITY_RELATION, TAG_TYPE_RESOURCE_RELATION, TAG_IDENTIFIER_CLASS, TagParams, EntityRelationValue, ResourceRelationValue } from "../../../evefrontier/systems/tag-system/types.sol";

import { ISOFAccessSystem } from "../../interfaces/ISOFAccessSystem.sol";
import { IWorldWithContext } from "../../../../IWorldWithContext.sol";

import { IEntitySystem } from "../../../evefrontier/interfaces/IEntitySystem.sol";
import { Utils as EntitySystemUtils } from "../../../evefrontier/systems/entity-system/Utils.sol";

import { SmartObjectFramework } from "../../../../inherit/SmartObjectFramework.sol";

/**
 * @title SOFAccessSystem
 * @author CCP Games
 * @dev Handles access control logic for SOF Systems (EntitySystem and TagSystem)
 */
contract SOFAccessSystem is ISOFAccessSystem, SmartObjectFramework {
  using WorldResourceIdInstance for ResourceId;

  /**
   * @notice Validates if caller has the required role to access an entity
   * @param entityId The ID of the entity to check access for
   * @param targetCallData The calldata of the target function
   * @dev Reverts if caller doesn't have the required role
   */
  function allowAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    if (!HasRole.getIsMember(Entity.getAccessRole(entityId), _callMsgSender(1))) {
      revert SOFAccess_RoleAccessDenied(Entity.getAccessRole(entityId), _callMsgSender(1));
    }
  }

  /**
   * @notice Validates access for class-scoped system-to-system calls only (no direct calls)
   * @param entityId The ID of the entity (class or object) to check
   * @param targetCallData The calldata of the target function
   */
  function allowClassScopedSystem(uint256 entityId, bytes memory targetCallData) public view {
    uint256 classId = _getClassId(entityId);
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    _allowClassScopedSystem(classId, callCount);
  }

  /**
   * @notice Validates if caller has the required class access role for an entity AND if the call is direct to the target function
   * @param entityId The ID of the entity to check access for
   * @param targetCallData The calldata of the target function
   * @dev Reverts if caller doesn't have the required class access role, if this is a system-to-system call, or if somone called this access logic directly
   */
  function allowDirectClassAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 classId = _getClassId(entityId);
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();

    if (callCount > 1) {
      // system-to-system call case
      revert SOFAccess_SystemAccessDenied(classId, msgSender);
    } else if (callCount == 1) {
      // direct call to the target system (the system this access logic is configured for)
      allowAccessRole(classId, targetCallData);
    } else {
      // direct call to this access logic
      revert SOFAccess_DirectCall();
    }
  }

  /**
   * @notice Validates if caller has the required access role for an entity (class access role for a calls and object access role ofr an object) AND if the call is direct to the target function
   * @param entityId The ID of the entity to check access for
   * @param targetCallData The calldata of the target function
   * @dev Reverts if caller doesn't have the required access role (class or object access respectively), if this is a system-to-system call, or if somone called this access logic directly
   */
  function allowDirectAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();

    if (callCount > 1) {
      // system-to-system call case
      revert SOFAccess_SystemAccessDenied(entityId, msgSender);
    } else if (callCount == 1) {
      // direct call to the target system (the system this access logic is configured for)
      allowAccessRole(entityId, targetCallData);
    } else {
      // direct call to this access logic
      revert SOFAccess_DirectCall();
    }
  }

  /**
   * @notice Validates access for class-scoped systems or direct class access role membership (class if a classId is passed, the object's class if an objectId is passed)
   * @param entityId The ID of the entity (class or object) to check
   * @param targetCallData The calldata of the target function
   * @dev Handles both direct calls (call depth 1) and class system-scoped calls (call depth > 1)
   */
  function allowClassScopedSystemOrDirectClassAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 classId = _getClassId(entityId);
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();

    if (callCount > 1) {
      // system-to-system call case
      _allowClassScopedSystem(classId, callCount);
    } else if (callCount == 1) {
      // direct call to the target system (the system this access logic is configured for)
      allowAccessRole(classId, targetCallData);
    } else {
      // direct call to this access logic
      revert SOFAccess_DirectCall();
    }
  }

  /**
   * @notice Validates access for class-scoped systems or direct access role (class access role if a classId was passed, object access role if an objectId was passed)
   * @param entityId The ID of the object to check access for
   * @param targetCallData The calldata of the target function
   * @dev Handles both direct calls (call depth 1) and class system-scoped calls (call depth > 1)
   */
  function allowClassScopedSystemOrDirectAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 classId = _getClassId(entityId);
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();

    // a direct entrypoint call to EntitySystem.sol will put this access call at callCount = 1
    if (callCount > 1) {
      // system-to-system call case
      _allowClassScopedSystem(classId, callCount);
    } else if (callCount == 1) {
      // direct call to the target system (the system this access logic is configured for)
      allowAccessRole(entityId, targetCallData);
    } else {
      // direct call to this access logic
      revert SOFAccess_DirectCall();
    }
  }

  /**
   * @notice Validates access for EntitySystem or direct role access
   * @param entityId The ID of the entity to check access for (object or class)
   * @param targetCallData The calldata of the target function
   * @dev Handles access control for TagSystem.sol functionality (only callable from EntitySystem.sol or directly via a role member)
   * @dev TODO: Add HookSystem.sol access to this when implemented
   */
  function allowEntitySystemOrDirectAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    // a direct entrypoint call to TagSystem.sol will put this access call at callCount = 1
    if (callCount > 1) {
      // if not a direct entrypoint call to TagSystem, (instead a subsequent internal call), then we only allow EntitySystem.sol as the target System of this function
      (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();
      ResourceId callingSystemId = SystemRegistry.get(msgSender);
      if (callingSystemId.unwrap() != EntitySystemUtils.entitySystemId().unwrap()) {
        // for TagSystem if an internal call is not from EntitySytem or a Class scoped system then we reject the call
        revert SOFAccess_SystemAccessDenied(entityId, msgSender);
      }
    } else if (callCount == 1) {
      allowAccessRole(entityId, targetCallData);
    } else {
      // callCount = 0, means this access function was called directly. It should only be called via an access() modifier, so we revert
      revert SOFAccess_DirectCall();
    }
  }

  function _getClassId(uint256 entityId) private view returns (uint256) {
    uint256 classId;
    if (EntityTagMap.getHasTag(entityId, TagIdLib.encode(TAG_TYPE_PROPERTY, TAG_IDENTIFIER_CLASS))) {
      classId = entityId;
    } else {
      EntityRelationValue memory entityRelationValue = abi.decode(
        EntityTagMap.getValue(entityId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(entityId)))),
        (EntityRelationValue)
      );
      classId = entityRelationValue.relatedEntityId;
    }
    return classId;
  }

  function _allowClassScopedSystem(uint256 classId, uint256 callCount) private view {
    if (callCount > 1) {
      // system-to-system call allowable if the previous call was from a Class scoped System
      (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
      ResourceId callingSystemId = SystemRegistry.get(msgSender);
      if (
        !EntityTagMap.getHasTag(
          classId,
          TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(callingSystemId)))
        )
      ) {
        revert SOFAccess_SystemAccessDenied(classId, msgSender);
      }
    } else {
      // we entertain no direct calls to this access logic (callCount = 0) nor to the targeted access controlled system (callCount = 1). i.e. it must be a system-to-system call
      revert SOFAccess_DirectCall();
    }
  }
}
