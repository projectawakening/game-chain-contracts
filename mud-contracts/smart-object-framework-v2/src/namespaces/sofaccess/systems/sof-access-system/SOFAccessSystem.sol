// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;
import { console } from "forge-std/console.sol";
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
import { InventoryUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/InventoryUtils.sol";
import { SmartStorageUnitUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-storage-unit/SmartStorageUnitUtils.sol";
import { SmartCharacterUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-character/SmartCharacterUtils.sol";
import { SmartGateUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-gate/SmartGateUtils.sol";
import { SmartTurretUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/smart-turret/SmartTurretUtils.sol";

import { SmartObjectFramework } from "../../../../inherit/SmartObjectFramework.sol";

/**
 * @title SOFAccessSystem
 * @author CCP Games
 * @dev Handles access control logic for SOF Systems (EntitySystem and TagSystem)
 */
contract SOFAccessSystem is ISOFAccessSystem, SmartObjectFramework {
  using WorldResourceIdInstance for ResourceId;

  /**
   * @notice Validates if caller has the required role to access an entity (and is directly calling)
   * @param entityId The ID of the entity to check access for
   * @param targetCallData The calldata of the target function
   * @dev Reverts if caller doesn't have the required role
   */
  function allowDirectAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    if (callCount == 1 && _checkAccessRole(entityId, _callMsgSender(1))) {
      return;
    }

    revert SOFAccess_AccessDenied(entityId, _callMsgSender(1));
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

    if (callCount == 1 && _checkAccessRole(classId, _callMsgSender(1))) {
      return;
    }

    revert SOFAccess_AccessDenied(entityId, msgSender);
  }

  /**
   * @notice Validates access for only class-scoped system-to-system calls only (no direct calls)
   * @param entityId The ID of the entity (class or object) to check
   * @param targetCallData The calldata of the target function
   */
  function allowClassScopedSystem(uint256 entityId, bytes memory targetCallData) public view {
    uint256 classId = _getClassId(entityId);
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    ResourceId callingSystemId = SystemRegistry.get(msgSender);

    if (callCount > 1 && _checkClassScopedSystem(classId, callingSystemId)) {
      return;
    }

    revert SOFAccess_AccessDenied(entityId, msgSender);
  }

  /**
   * @notice Validates access for class-scoped systems or direct class access role membership (for a class if a classId is passed, or the object's class if an objectId is passed)
   * @param entityId The ID of the entity (class or object) to check
   * @param targetCallData The calldata of the target function
   * @dev Handles both direct calls (call depth 1) and class system-scoped calls (call depth > 1)
   */
  function allowClassScopedSystemOrDirectClassAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 classId = _getClassId(entityId);
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    ResourceId callingSystemId = SystemRegistry.get(msgSender);

    if (callCount > 1 && _checkClassScopedSystem(classId, callingSystemId)) {
      // system-to-system call case
      return;
    } else if (callCount == 1 && _checkAccessRole(classId, _callMsgSender(1))) {
      // entry point direct call case
      return;
    }

    revert SOFAccess_AccessDenied(entityId, msgSender);
  }

  /**
   * @notice Validates access for class-scoped systems or direct access role (for class access role if a classId was passed, or an object access role if an objectId was passed)
   * @param entityId The ID of the object to check access for
   * @param targetCallData The calldata of the target function
   * @dev Handles both direct calls (call depth 1) and class system-scoped calls (call depth > 1)
   */
  function allowClassScopedSystemOrDirectAccessRole(uint256 entityId, bytes memory targetCallData) public view {
    uint256 classId = _getClassId(entityId);
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    ResourceId callingSystemId = SystemRegistry.get(msgSender);

    if (callCount > 1 && _checkClassScopedSystem(classId, callingSystemId)) {
      // system-to-system call case
      return;
    } else if (callCount == 1 && _checkAccessRole(entityId, _callMsgSender(callCount))) {
      // entry point direct call case
      return;
    }

    revert SOFAccess_AccessDenied(entityId, msgSender);
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
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    ResourceId callingSystemId = SystemRegistry.get(msgSender);

    if (callCount > 1 && (callingSystemId.unwrap() == EntitySystemUtils.entitySystemId().unwrap())) {
      return;
    } else if (callCount == 1 && _checkAccessRole(entityId, _callMsgSender(1))) {
      return;
    }

    revert SOFAccess_AccessDenied(entityId, msgSender);
  }

  function allowEntitySystemOrClassScopedSystem(uint256 entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    ResourceId callingSystemId = SystemRegistry.get(msgSender);

    if (callCount > 1 && callingSystemId.unwrap() != EntitySystemUtils.entitySystemId().unwrap()) {
      uint256 classId = _getClassId(entityId);
      if (_checkClassScopedSystem(classId, callingSystemId)) {
        return;
      }
    } else if (callCount > 1 && callingSystemId.unwrap() == EntitySystemUtils.entitySystemId().unwrap()) {
      // EntitySystem.registerClass, EntitySyste.scopedRegisterClass, EntitySystem.initialize, EntitySystem.deleteClass, EntitySystem.deleteObject
      return;
    }

    revert SOFAccess_AccessDenied(entityId, msgSender);
  }

  // deleteClass - revoke all members and delete role for class
  // - direct call only,
  // - should check _callMsgSender(1) is member of class access role for scopedRevokeAll

  // deleteObject  - revoke all members and delete role for object
  // - class scoped system or direct call (class admin),
  // - should check _callMsgSender(1) is member of object access role for scopedRevokeAll in the case of class scoped system call,
  // - should check if _callMsgSender(1) is member of object's class access role for scopedRevokeAll if direct call

  function allowDefinedSystems(uint256 entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    if (callCount > 1) {
      // system-to-system call case
      ResourceId callingSystemId = SystemRegistry.get(msgSender);
      if (
        callingSystemId.unwrap() == InventoryUtils.ephemeralInventorySystemId().unwrap() ||
        callingSystemId.unwrap() == InventoryUtils.inventorySystemId().unwrap() ||
        callingSystemId.unwrap() == SmartStorageUnitUtils.smartStorageUnitSystemId().unwrap() ||
        callingSystemId.unwrap() == SmartCharacterUtils.smartCharacterSystemId().unwrap() ||
        callingSystemId.unwrap() == SmartTurretUtils.smartTurretSystemId().unwrap() ||
        callingSystemId.unwrap() == SmartGateUtils.smartGateSystemId().unwrap()
      ) {
        return;
      }
    }

    revert SOFAccess_AccessDenied(entityId, msgSender);
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

  function _checkClassScopedSystem(uint256 classId, ResourceId callingSystemId) private view returns (bool) {
    return
      EntityTagMap.getHasTag(
        classId,
        TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(callingSystemId)))
      );
  }

  function _checkAccessRole(uint256 entityId, address caller) private view returns (bool) {
    // console.log(entityId);
    // console.log(caller);
    // console.logBytes32(Entity.getAccessRole(entityId));
    // console.logBytes32(keccak256(abi.encodePacked("ACESS_ROLE", entityId)));
    return HasRole.getIsMember(Entity.getAccessRole(entityId), caller);
  }
}
