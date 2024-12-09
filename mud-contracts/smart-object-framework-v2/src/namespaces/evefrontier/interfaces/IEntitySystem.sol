// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Id } from "../../../libs/Id.sol";

/**
 * @title IEntitySystem
 * @dev An interface for the Entity System functionality
 */
interface IEntitySystem {
  function registerClass(Id classId, bytes32 accessRole, Id[] memory systemTagIds) external;
  function setClassAccessRole(Id classId, bytes32 newAccessRole) external;
  function deleteClass(Id classId) external;
  function deleteClasses(Id[] memory classIds) external;
  function instantiate(Id classId, Id objectId) external;
  function setObjectAccessRole(Id objectId, bytes32 newAccessRole) external;
  function deleteObject(Id objectId) external;
  function deleteObjects(Id[] memory objectIds) external;

  error Entity_InvalidEntityId(Id invalidId);
  error Entity_InvalidEntityType(bytes2 givenType);
  error Entity_WrongEntityType(bytes2 givenType, bytes2[] expectedTypes);
  error Entity_ClassAlreadyExists(Id classId);
  error Entity_ClassDoesNotExist(Id classId);
  error Entity_ClassHasObjects(Id classId, uint256 numberOfObjects);
  error Entity_RoleAccessDenied(bytes32 accessRole, address caller);
  error Entity_ObjectAlreadyExists(Id objectId, Id instanceClass);
  error Entity_ObjectDoesNotExist(Id objectId);
  error Entity_RoleDoesNotExist(bytes32 role);
}
