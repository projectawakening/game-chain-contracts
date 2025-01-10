// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { IEntitySystem } from "../../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { Utils as EntitySystemUtils } from "../../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { ITagSystem } from "../../src/namespaces/evefrontier/interfaces/ITagSystem.sol";
import { Utils as TagSystemUtils } from "../../src/namespaces/evefrontier/systems/tag-system/Utils.sol";

import { TagId } from "../../src/libs/TagId.sol";
import { TagParams } from "../../src/namespaces/evefrontier/systems/tag-system/types.sol";

import { SmartObjectFramework } from "../../src/inherit/SmartObjectFramework.sol";

contract ClassScopedMock is SmartObjectFramework {
  ResourceId ENTITY_SYSTEM_ID = EntitySystemUtils.entitySystemId();
  ResourceId TAG_SYSTEM_ID = TagSystemUtils.tagSystemId();

  function callSetTag(uint256 entityId, TagParams memory tagParams) public scope(entityId) {
    IWorldKernel(_world()).call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.setTag, (entityId, tagParams)));
  }

  function callRemoveTag(uint256 entityId, TagId tagId) public scope(entityId) {
    IWorldKernel(_world()).call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.removeTag, (entityId, tagId)));
  }

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

  function callInstantiate(uint256 classId, uint256 objectId) public scope(classId) {
    IWorldKernel(_world()).call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));
  }

  function callDeleteClass(uint256 classId) public scope(classId) {
    IWorldKernel(_world()).call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));
  }

  function callDeleteObject(uint256 objectId) public scope(objectId) {
    IWorldKernel(_world()).call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));
  }
}
