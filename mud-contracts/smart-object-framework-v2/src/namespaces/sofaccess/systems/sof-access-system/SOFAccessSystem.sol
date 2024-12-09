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
 * @dev access logic for the SOF Systems {EntitySystem.sol} and {TagSystem.sol}
 */
contract SOFAccessSystem is ISOFAccessSystem, SmartObjectFramework {
  using WorldResourceIdInstance for ResourceId;

  // EnitySystem.sol access logic
  function allowClassAccessRole(Id classId, bytes memory targetCallData) public view {
    if(!HasRole.get(Classes.getAccessRole(classId), _callMsgSender(1))) {
      revert SOFAccess_RoleAccessDenied(Classes.getAccessRole(classId), _callMsgSender(1));
    }
  }

  function allowClassScopedSystemOrDirectClassAccessRole(Id entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    Id classId;
    if (entityId.getType() == ENTITY_CLASS) {
      classId = entityId;
    } else {
      classId = Objects.getClass(entityId);
    }
    // a direct entrypoint call to EntitySystem.sol will put this access call at callCount = 1
    if (callCount > 1) { // not a direct entrypoint call to EntitySystem.sol but allowable if the previous call was from a Class scoped System
      (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();
      ResourceId callingSystemId = SystemRegistry.get(msgSender);
      if (!ClassSystemTagMap.getHasTag(classId, Id.wrap(ResourceId.unwrap(callingSystemId)))) {
        revert SOFAccess_SystemAccessDenied(classId, msgSender);
      }
    } else if (callCount == 1) { // if this is direct call to EntitySystem.sol, we check for Class access role membership
      if (!HasRole.get(Classes.getAccessRole(classId), _callMsgSender(1))) {
        revert SOFAccess_RoleAccessDenied(Classes.getAccessRole(classId), _callMsgSender(1));
      }
    } else { // callCount = 0, means this access function was called directly. It should only be called via an access() modifier from another function, so we revert
      revert SOFAccess_DirectCall();
    }
  }

  function allowClassScopedSystemOrDirectObjectAccessRole(Id objectId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    // a direct entrypoint call to EntitySystem.sol will put this access call at callCount = 1
    if(callCount > 1) { // not a direct entrypoint call to EntitySystem.sol but allowable if the call was from an Class scoped System
      (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();
      ResourceId callingSystemId = SystemRegistry.get(msgSender);
      Id classId = Objects.getClass(objectId);
      if (!ClassSystemTagMap.getHasTag(classId, Id.wrap(ResourceId.unwrap(callingSystemId)))) {
        revert SOFAccess_SystemAccessDenied(objectId, msgSender);
      }
    } else if (callCount == 1) { // if this is direct call to EntitySystem.sol, we check for Object access role membership
      if(!HasRole.get(Objects.getAccessRole(objectId), _callMsgSender(1))) {
        revert SOFAccess_RoleAccessDenied(Objects.getAccessRole(objectId), _callMsgSender(1));
      }
    } else { // callCount = 0, means this access function was called directly. It should only be called via an access() modifier from another function, so we revert
      revert SOFAccess_DirectCall();
    }
  }
  
  // TagSystem.sol access logic
  // TODO: add HookSystem access to this (when it comes)
  function allowEntitySystemOrDirectAccessRole(Id entityId, bytes memory targetCallData) public view {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    // a direct entrypoint call to TagSystem.sol will put this access call at callCount = 1
    if(callCount > 1) { // if not a direct entrypoint call to TagSystem, (instead a subsequent internal call), then we only allow EntitySystem.sol as the target System of this function
      (ResourceId systemId, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext();
      
      if(systemId.unwrap() != EntitySystemUtils.entitySystemId().unwrap()) { // for TagSystem if an internal call is not from EntitySytem or a Class scoped system then we reject the call
        revert SOFAccess_SystemAccessDenied(entityId, msgSender);
      }
    } else if (callCount == 1) { // this is direct call to TagSystem.sol
      bytes2 entityType = entityId.getType();
      if (entityType == ENTITY_CLASS) { // if the entity is a Class, we check for Class access role membership
        if(!HasRole.get(Classes.getAccessRole(entityId), _callMsgSender(1))) {
          revert SOFAccess_RoleAccessDenied(Classes.getAccessRole(entityId), _callMsgSender(1));
        }
      } else { // if the entity is an Object, we check for Object access role membership
        if(!HasRole.get(Objects.getAccessRole(entityId), _callMsgSender(1))) {
          revert SOFAccess_RoleAccessDenied(Objects.getAccessRole(entityId), _callMsgSender(1));
        }
      }
    } else { // callCount = 0, means this access function was called directly. It should only be called via an access() modifier, so we revert
      revert SOFAccess_DirectCall();
    }
  }
}
  