// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";

import { Objects } from "../../../evefrontier/codegen/tables/Objects.sol";
import { Classes } from "../../../evefrontier/codegen/tables/Classes.sol";
import { ClassSystemTagMap } from "../../../evefrontier/codegen/tables/ClassSystemTagMap.sol";
import { ObjectSystemTagMap } from "../../../evefrontier/codegen/tables/ObjectSystemTagMap.sol";
import { Role } from "../../../evefrontier/codegen/tables/Role.sol";
import { HasRole } from "../../../evefrontier/codegen/tables/HasRole.sol";

import { Id } from "../../../../libs/Id.sol";
import { ENTITY_CLASS, ENTITY_OBJECT } from "../../../../types/entityTypes.sol";

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
   * @notice Validates if caller has the required role to access a class
   * @param classId The ID of the class to check access for
   * @param targetCallData The calldata of the target function
   * @dev Reverts if caller doesn't have the required role
   */
  function allowClassAccessRole(Id classId, bytes memory targetCallData) public view {
    if (!HasRole.get(Classes.getAccessRole(classId), _callMsgSender(1))) {
      revert SOFAccess_RoleAccessDenied(Classes.getAccessRole(classId), _callMsgSender(1));
    }
  }

  /**
   * @notice Validates access for class-scoped systems or direct class access
   * @param entityId The ID of the entity (class or object) to check
   * @param targetCallData The calldata of the target function
   * @dev Handles both direct calls (call depth 1) and class system-scoped calls (call depth > 1)
   */
  function allowClassScopedSystemOrDirectClassAccessRole(Id entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    Id classId;
    if (entityId.getType() == ENTITY_CLASS) {
      classId = entityId;
    } else {
      classId = Objects.getClass(entityId);
    }
    // a direct entrypoint call to EntitySystem.sol will put this access call at callCount = 1
    if (callCount > 1) {
      // not a direct entrypoint call to EntitySystem.sol but allowable if the previous call was from a Class scoped System
      (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();
      ResourceId callingSystemId = SystemRegistry.get(msgSender);
      if (!ClassSystemTagMap.getHasTag(classId, Id.wrap(ResourceId.unwrap(callingSystemId)))) {
        revert SOFAccess_SystemAccessDenied(classId, msgSender);
      }
    } else if (callCount == 1) {
      // if this is direct call to EntitySystem.sol, we check for Class access role membership
      if (!HasRole.get(Classes.getAccessRole(classId), _callMsgSender(1))) {
        revert SOFAccess_RoleAccessDenied(Classes.getAccessRole(classId), _callMsgSender(1));
      }
    } else {
      // callCount = 0, means this access function was called directly. It should only be called via an access() modifier from another function, so we revert
      revert SOFAccess_DirectCall();
    }
  }
  /**
   * @notice Validates access for class-scoped systems or direct object access
   * @param objectId The ID of the object to check access for
   * @param targetCallData The calldata of the target function
   * @dev Handles both direct calls (call depth 1) and class system-scoped calls (call depth > 1)
   */
  function allowClassScopedSystemOrDirectObjectAccessRole(Id objectId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    // a direct entrypoint call to EntitySystem.sol will put this access call at callCount = 1
    if (callCount > 1) {
      // not a direct entrypoint call to EntitySystem.sol but allowable if the call was from an Class scoped System
      (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();
      ResourceId callingSystemId = SystemRegistry.get(msgSender);
      Id classId = Objects.getClass(objectId);
      if (!ClassSystemTagMap.getHasTag(classId, Id.wrap(ResourceId.unwrap(callingSystemId)))) {
        revert SOFAccess_SystemAccessDenied(objectId, msgSender);
      }
    } else if (callCount == 1) {
      // if this is direct call to EntitySystem.sol, we check for Object access role membership
      if (!HasRole.get(Objects.getAccessRole(objectId), _callMsgSender(1))) {
        revert SOFAccess_RoleAccessDenied(Objects.getAccessRole(objectId), _callMsgSender(1));
      }
    } else {
      // callCount = 0, means this access function was called directly. It should only be called via an access() modifier from another function, so we revert
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
  function allowEntitySystemOrDirectAccessRole(Id entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    // a direct entrypoint call to TagSystem.sol will put this access call at callCount = 1
    if (callCount > 1) {
      // if not a direct entrypoint call to TagSystem, (instead a subsequent internal call), then we only allow EntitySystem.sol as the target System of this function
      (ResourceId systemId, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();

      if (systemId.unwrap() != EntitySystemUtils.entitySystemId().unwrap()) {
        // for TagSystem if an internal call is not from EntitySytem or a Class scoped system then we reject the call
        revert SOFAccess_SystemAccessDenied(entityId, msgSender);
      }
    } else if (callCount == 1) {
      // this is direct call to TagSystem.sol
      bytes2 entityType = entityId.getType();
      if (entityType == ENTITY_CLASS) {
        // if the entity is a Class, we check for Class access role membership
        if (!HasRole.get(Classes.getAccessRole(entityId), _callMsgSender(1))) {
          revert SOFAccess_RoleAccessDenied(Classes.getAccessRole(entityId), _callMsgSender(1));
        }
      } else {
        // if the entity is an Object, we check for Object access role membership
        if (!HasRole.get(Objects.getAccessRole(entityId), _callMsgSender(1))) {
          revert SOFAccess_RoleAccessDenied(Objects.getAccessRole(entityId), _callMsgSender(1));
        }
      }
    } else {
      // callCount = 0, means this access function was called directly. It should only be called via an access() modifier, so we revert
      revert SOFAccess_DirectCall();
    }
  }
}
