// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { IEntitySystem } from "../../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { Utils as EntitySystemUtils } from "../../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { ITagSystem } from "../../src/namespaces/evefrontier/interfaces/ITagSystem.sol";
import { Utils as TagSystemUtils } from "../../src/namespaces/evefrontier/systems/tag-system/Utils.sol";
import { IRoleManagementSystem } from "../../src/namespaces/evefrontier/interfaces/IRoleManagementSystem.sol";
import { Utils as RoleManagementUtils } from "../../src/namespaces/evefrontier/systems/role-management-system/Utils.sol";

import { TagId } from "../../src/libs/TagId.sol";
import { TagParams } from "../../src/namespaces/evefrontier/systems/tag-system/types.sol";

import { SmartObjectFramework } from "../../src/inherit/SmartObjectFramework.sol";

contract ClassScopedMock is SmartObjectFramework {
  ResourceId ENTITY_SYSTEM_ID = EntitySystemUtils.entitySystemId();
  ResourceId TAG_SYSTEM_ID = TagSystemUtils.tagSystemId();
  ResourceId ROLE_MANAGEMENT_SYSTEM_ID = RoleManagementUtils.roleManagementSystemId();

  // TagSystem.sol
  function callSetTag(uint256 entityId, TagParams memory tagParams) public scope(entityId) {
    IWorldKernel(_world()).call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.setTag, (entityId, tagParams)));
  }

  function callRemoveTag(uint256 entityId, TagId tagId) public scope(entityId) {
    IWorldKernel(_world()).call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.removeTag, (entityId, tagId)));
  }

  // EntitySystem.sol
  function callSetClassAccessRole(uint256 classId, bytes32 newAccessRole) public scope(classId) {
    IWorldKernel(_world()).call(
      ENTITY_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.setClassAccessRole, (classId, newAccessRole))
    );
  }

  function callSetObjectAccessRole(uint256 objectId, bytes32 newAccessRole) public scope(objectId) {
    IWorldKernel(_world()).call(
      ENTITY_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.setObjectAccessRole, (objectId, newAccessRole))
    );
  }

  function callInstantiate(uint256 classId, uint256 objectId, address account) public scope(classId) {
    IWorldKernel(_world()).call(
      ENTITY_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.instantiate, (classId, objectId, account))
    );
  }

  function callDeleteClass(uint256 classId) public scope(classId) {
    IWorldKernel(_world()).call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));
  }

  function callDeleteObject(uint256 objectId) public scope(objectId) {
    IWorldKernel(_world()).call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));
  }

  // RoleManagement.sol
  function callScopedCreateRole(uint256 objectId, bytes32 role, bytes32 admin, address account) public {
    IWorldKernel(_world()).call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.scopedCreateRole, (objectId, role, admin, account))
    );
  }

  function callScopedTransferRoleAdmin(uint256 objectId, bytes32 role, bytes32 newAdmin) public {
    IWorldKernel(_world()).call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.scopedTransferRoleAdmin, (objectId, role, newAdmin))
    );
  }

  function callScopedGrantRole(uint256 objectId, bytes32 role, address account) public {
    IWorldKernel(_world()).call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.scopedGrantRole, (objectId, role, account))
    );
  }

  function callScopedRevokeRole(uint256 objectId, bytes32 role, address account) public {
    IWorldKernel(_world()).call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.scopedRevokeRole, (objectId, role, account))
    );
  }

  function callScopedRenounceRole(uint256 objectId, bytes32 role, address account) public {
    IWorldKernel(_world()).call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.scopedRenounceRole, (objectId, role, account))
    );
  }

  function callScopedRevokeAll(uint256 objectId, bytes32 role) public {
    IWorldKernel(_world()).call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.scopedRevokeAll, (objectId, role))
    );
  }
}
