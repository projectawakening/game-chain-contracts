// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { Classes, ClassesData } from "../../codegen/tables/Classes.sol";
import { ClassSystemTagMap } from "../../codegen/tables/ClassSystemTagMap.sol";
import { ClassObjectMap, ClassObjectMapData } from "../../codegen/tables/ClassObjectMap.sol";
import { Objects, ObjectsData } from "../../codegen/tables/Objects.sol";
import { Role } from "../../codegen/tables/Role.sol";
import { HasRole } from "../../codegen/tables/HasRole.sol";

import { Id, IdLib } from "../../../../libs/Id.sol";
import { ENTITY_CLASS, ENTITY_OBJECT } from "../../../../types/entityTypes.sol";
import { TAG_SYSTEM } from "../../../../types/tagTypes.sol";

import { ITagSystem } from "../../interfaces/ITagSystem.sol";
import { IEntitySystem } from "../../interfaces/IEntitySystem.sol";

import { Utils as TagSystemUtils } from "../tag-system/Utils.sol";

import { SmartObjectFramework } from "../../../../inherit/SmartObjectFramework.sol";

/**
 * @title EntitySystem
 * @author CCP Games
 * @notice Manage Class and Object creation/deletion through the use of reference Ids { see, `libs/Id.sol` and `types/entityTypes.sol`}
 */
contract EntitySystem is IEntitySystem, SmartObjectFramework {
  /**
   * @notice Registers a new Class Entity into the SOF framework
   * @param classId A unique ENTITY_CLASS type Id for the new Class Entity
   * @param accessRole A bytes32 access control role Id to be assigned to the class {see, RoleManagementSystem.sol}
   * @param systemTags An array of TAG_SYSTEM type Ids which correlating to MUD System ResourceIds
   * @dev Validates class ID, type and existence before registration
   * @dev Requires caller to be a member of the specified `accessRole`
   */
  function registerClass(Id classId, bytes32 accessRole, Id[] memory systemTags) public context enforceCallCount(1) {
    if (Id.unwrap(classId) == bytes32(0)) {
      revert Entity_InvalidEntityId(classId);
    }
    if (classId.getType() != ENTITY_CLASS) {
      bytes2[] memory expected = new bytes2[](1);
      expected[0] = ENTITY_CLASS;
      revert Entity_WrongEntityType(classId.getType(), expected);
    }
    if (Classes.getExists(classId)) {
      revert Entity_ClassAlreadyExists(classId);
    }

    if (!HasRole.get(accessRole, _callMsgSender(1))) {
      revert Entity_RoleAccessDenied(accessRole, _callMsgSender(1));
    }

    Classes.set(classId, true, accessRole, new bytes32[](0), new bytes32[](0));

    IWorldKernel(_world()).call(
      TagSystemUtils.tagSystemId(),
      abi.encodeCall(ITagSystem.setSystemTags, (classId, systemTags))
    );
  }

  /**
   * @notice Sets a new Class Access Role for a given Class Entity
   * @param classId A unique ENTITY_CLASS type Id for the new Class Entity
   * @param newAccessRole A bytes32 access control role Id to be assigned to the class {see, RoleManagementSystem.sol}
   * @dev Validates `classId`, and `accessRole` existence
   * @dev Requires a direct caller to be a member of the current `accessRole`, or a System that is tagged to the Class
   */
  function setClassAccessRole(Id classId, bytes32 newAccessRole) public context access(classId) {
    if (!Classes.getExists(classId)) {
      revert Entity_ClassDoesNotExist(classId);
    }
    if (!Role.getExists(newAccessRole)) {
      revert Entity_RoleDoesNotExist(newAccessRole);
    }
    Classes.setAccessRole(classId, newAccessRole);
  }

  /**
   * @notice Delete a registered Class
   * @param classId An ENTITY_CLASS type Id reference of an existing Class
   * @dev Validates `classId` existence before executing
   * @dev Handles cleanup of Class references and associated system tags
   * @dev Require the class to not have any Objects associated with it
   * @dev Requires a direct call to the `deleteClass` function (cannot be called from another System)
   * @dev Requires caller to be a member of the Class `accessRole`
   * @dev Warning: Dependent data in tagged Systems should be handled before deletion
   */
  function deleteClass(Id classId) public context enforceCallCount(1) access(classId) {
    if (!Classes.getExists(classId)) {
      revert Entity_ClassDoesNotExist(classId);
    }

    ClassesData memory class = Classes.get(classId);
    if (class.objects.length > 0) {
      revert Entity_ClassHasObjects(classId, class.objects.length);
    }

    Id[] memory systemTags = new Id[](class.systemTags.length);
    for (uint i = 0; i < class.systemTags.length; i++) {
      systemTags[i] = Id.wrap(class.systemTags[i]);
    }

    IWorldKernel(_world()).call(
      TagSystemUtils.tagSystemId(),
      abi.encodeCall(ITagSystem.removeSystemTags, (classId, systemTags))
    );

    Classes.deleteRecord(classId);
  }

  /**
   * @notice Deletes multiple registered Classes
   * @param classIds An array of ENTITY_CLASS type Id references of existing Classes
   * @dev Iteratively calls deleteClass for each classId in `classIds`
   */
  function deleteClasses(Id[] memory classIds) public {
    for (uint i = 0; i < classIds.length; i++) {
      deleteClass(classIds[i]);
    }
  }

  /**
   * @notice Instantiate an Object from a given parent Class
   * @param classId The ENTITY_CLASS type Id of the parent Class
   * @param objectId The ENTITY_OBJECT type Id for the new instance
   * @dev Validates `classId` existence, `objectId` non-existence, and `objectId` type
   * @dev Maintains class-object relationships in mapping tables
   * @dev Requires a direct caller to be a member of the parent Class `accessRole` or a System that is tagged to the parent Class
   */
  function instantiate(Id classId, Id objectId) public context access(classId) {
    if (!Classes.getExists(classId)) {
      revert Entity_ClassDoesNotExist(classId);
    }

    if (Id.unwrap(objectId) == bytes32(0)) {
      revert Entity_InvalidEntityId(objectId);
    }
    if (objectId.getType() != ENTITY_OBJECT) {
      bytes2[] memory expected = new bytes2[](1);
      expected[0] = ENTITY_OBJECT;
      revert Entity_WrongEntityType(objectId.getType(), expected);
    }
    if (Objects.getExists(objectId)) {
      Id instanceClass = Objects.getClass(objectId);
      revert Entity_ObjectAlreadyExists(objectId, instanceClass);
    }

    ClassObjectMap.set(classId, objectId, true, Classes.lengthObjects(classId));
    Classes.pushObjects(classId, Id.unwrap(objectId));
    Objects.set(objectId, true, classId, bytes32(0), new bytes32[](0));
  }
  /**
   * @notice Sets a new Object Access Role for a given Object
   * @param objectId An Object Id for an existing Object
   * @param newAccessRole A bytes32 access control role Id to be assigned to the object {see, RoleManagementSystem.sol}
   * @dev Validates `objectId` existence, and `newAccessRole` existence
   * @dev Initially only settable via a Class tagged System, thereafter callable directly by an Object accessRole member (or a System that is tagged to the Object's parent Class)
   */
  function setObjectAccessRole(Id objectId, bytes32 newAccessRole) public context access(objectId) {
    if (!Objects.getExists(objectId)) {
      revert Entity_ObjectDoesNotExist(objectId);
    }
    if (!Role.getExists(newAccessRole)) {
      revert Entity_RoleDoesNotExist(newAccessRole);
    }
    Objects.setAccessRole(objectId, newAccessRole);
  }

  /**
   * @notice Delete an instantiated Object
   * @param objectId An ENTITY_OBJECT type Id of the object to delete
   * @dev Handles cleanup of object references and associated system tags
   * @dev Requires a direct caller to be a member of the Object's parent Class `accessRole` or a System that is tagged to the Object's parent Class
   * @dev Warning: Dependent data in tagged Systems should be handled before deletion
   */
  function deleteObject(Id objectId) public context access(objectId) {
    if (!Objects.getExists(objectId)) {
      revert Entity_ObjectDoesNotExist(objectId);
    }

    ObjectsData memory object = Objects.get(objectId);
    ClassObjectMapData memory classObjectMapData = ClassObjectMap.get(object.class, objectId);

    Classes.updateObjects(
      object.class,
      classObjectMapData.objectIndex,
      Classes.getItemObjects(object.class, Classes.lengthObjects(object.class) - 1)
    );

    ClassObjectMap.setObjectIndex(
      object.class,
      Id.wrap(Classes.getItemObjects(object.class, Classes.lengthObjects(object.class) - 1)),
      classObjectMapData.objectIndex
    );

    ClassObjectMap.deleteRecord(object.class, objectId);

    Classes.popObjects(object.class);

    Id[] memory systemTags = new Id[](object.systemTags.length);
    for (uint i = 0; i < object.systemTags.length; i++) {
      systemTags[i] = Id.wrap(object.systemTags[i]);
    }

    IWorldKernel(_world()).call(
      TagSystemUtils.tagSystemId(),
      abi.encodeCall(ITagSystem.removeSystemTags, (objectId, systemTags))
    );

    Objects.deleteRecord(objectId);
  }

  /**
   * @notice Deletes multiple instantiated Objects
   * @param objectIds An array of ENTITY_OBJECT type Ids to delete
   * @dev Iteratively calls deleteObject for each objectId in `objectIds`
   */
  function deleteObjects(Id[] memory objectIds) public {
    for (uint i = 0; i < objectIds.length; i++) {
      deleteObject(objectIds[i]);
    }
  }
}
