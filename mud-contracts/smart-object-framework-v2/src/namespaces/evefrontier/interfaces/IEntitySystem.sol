// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { TagId } from "../../../libs/TagId.sol";

/**
 * @title IEntitySystem
 * @dev An interface for the Entity System functionality
 */
interface IEntitySystem {
  function registerClass(uint256 classId, ResourceId[] memory scopedSystems) external;
  function scopedRegisterClass(uint256 classId, address accessRoleMember, ResourceId[] memory scopedSystems) external;
  function setClassAccessRole(uint256 classId, bytes32 newAccessRole) external;
  function deleteClass(uint256 classId) external;
  function deleteClasses(uint256[] memory classIds) external;
  function instantiate(uint256 classId, uint256 objectId, address accessRoleMember) external;
  function setObjectAccessRole(uint256 objectId, bytes32 newAccessRole) external;
  function deleteObject(uint256 objectId) external;
  function deleteObjects(uint256[] memory objectIds) external;

  error Entity_InvalidEntityId(uint256 entityId);
  error Entity_EntityAlreadyExists(uint256 entityId);
  error Entity_EntityDoesNotExist(uint256 classId);
  error Entity_PropertyTagNotFound(uint256 entityId, TagId tagId);
  error Entity_EntityRelationsFound(uint256 classId, uint256 numOfTags);
  error Entity_BadRoleConfirmation();
  error Entity_RoleDoesNotExist(bytes32 role);
}
