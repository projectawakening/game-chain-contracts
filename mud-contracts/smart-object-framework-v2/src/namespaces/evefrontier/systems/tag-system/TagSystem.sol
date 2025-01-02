// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { Classes } from "../../codegen/tables/Classes.sol";
import { ClassSystemTagMap, ClassSystemTagMapData } from "../../codegen/tables/ClassSystemTagMap.sol";
import { Objects } from "../../codegen/tables/Objects.sol";
import { ObjectSystemTagMap, ObjectSystemTagMapData } from "../../codegen/tables/ObjectSystemTagMap.sol";
import { SystemTags } from "../../codegen/tables/SystemTags.sol";

import { Id, IdLib } from "../../../../libs/Id.sol";
import { ENTITY_CLASS, ENTITY_OBJECT } from "../../../../types/entityTypes.sol";
import { TAG_SYSTEM } from "../../../../types/tagTypes.sol";

import { IEntitySystem } from "../../interfaces/IEntitySystem.sol";
import { ITagSystem } from "../../interfaces/ITagSystem.sol";

import { SmartObjectFramework } from "../../../../inherit/SmartObjectFramework.sol";

contract TagSystem is ITagSystem, SmartObjectFramework {
  /**
   * @notice set a SystemTag for a Class or Object
   * @param entityId An Id referencing an existing Class or Object to tag with `systemTagId`
   * @param systemTagId A TAG_SYSTEM type Id referencing a MUD System that has been registered on to the World which will be tagged to `entityId`
   */
  function setSystemTag(Id entityId, Id systemTagId) public context access(entityId) {
    _setSystemTag(entityId, systemTagId);
  }

  /**
   * @notice set multiple SystemTags for a Class or Object
   * @param entityId An Id referencing an existing Class or Object to tag with each System reference in `systemTagIds`
   * @param systemTagIds An array of TAG_SYSTEM type Ids each referencing a MUD System that has been registered on to the World and each of which will be tagged to `entityId`
   */
  function setSystemTags(Id entityId, Id[] memory systemTagIds) public {
    for (uint i = 0; i < systemTagIds.length; i++) {
      _setSystemTag(entityId, systemTagIds[i]);
    }
  }

  /**
   * @notice remove a SystemTag for a Class or Object
   * @dev removing a SystemTag from a Class may trigger/require dependent data deletions of Class/Object data entries in that System's associated Tables. Be sure to handle these dependencies accordingly in your System logic before removing a SystemTag
   * @param entityId An Id referencing an existing Class or Object to remove each System reference in `systemTagIds` from
   * @param systemTagId A TAG_SYSTEM type Id referencing a MUD System to remove from `entityId`
   */
  function removeSystemTag(Id entityId, Id systemTagId) public context access(entityId) {
    _removeSystemTag(entityId, systemTagId);
  }

  /**
   * @notice remove multiple SystemTags for a Class or Object
   * @param entityId An ENTITY_CLASS type Id referencing an existing Class or Object to tag with `systemTagId`
   * @param systemTagIds An array of TAG_SYSTEM type Ids each referencing a MUD System to remove from `entityId`
   */
  function removeSystemTags(Id entityId, Id[] memory systemTagIds) public {
    for (uint i = 0; i < systemTagIds.length; i++) {
      _removeSystemTag(entityId, systemTagIds[i]);
    }
  }

  function _setSystemTag(Id entityId, Id tagId) private {
    if (Id.unwrap(tagId) == bytes32(0)) {
      revert Tag_InvalidTagId(tagId);
    }
    if (tagId.getType() != TAG_SYSTEM) {
      bytes2[] memory expected = new bytes2[](1);
      expected[0] = TAG_SYSTEM;
      revert Tag_WrongTagType(tagId.getType(), expected);
    }

    ResourceId systemId = ResourceId.wrap((Id.unwrap(tagId)));
    if (!(ResourceIds.getExists(systemId))) {
      revert Tag_SystemNotRegistered(systemId);
    }

    if (!SystemTags.getExists(tagId)) {
      SystemTags.set(tagId, true, new bytes32[](0), new bytes32[](0));
    }

    bytes2 entityType = entityId.getType();
    if (entityType == ENTITY_CLASS) {
      if (!Classes.getExists(entityId)) {
        revert IEntitySystem.Entity_ClassDoesNotExist(entityId);
      }
      if (!ClassSystemTagMap.getHasTag(entityId, tagId)) {
        ClassSystemTagMap.set(
          entityId,
          tagId,
          true,
          SystemTags.lengthClasses(tagId),
          Classes.lengthSystemTags(entityId)
        );
        Classes.pushSystemTags(entityId, Id.unwrap(tagId));
        SystemTags.pushClasses(tagId, Id.unwrap(entityId));
      } else {
        revert Tag_EntityAlreadyHasTag(entityId, tagId);
      }
    } else if (entityType == ENTITY_OBJECT) {
      if (!Objects.getExists(entityId)) {
        revert IEntitySystem.Entity_ObjectDoesNotExist(entityId);
      }
      if (!ObjectSystemTagMap.getHasTag(entityId, tagId)) {
        ObjectSystemTagMap.set(
          entityId,
          tagId,
          true,
          SystemTags.lengthObjects(tagId),
          Objects.lengthSystemTags(entityId)
        );
        Objects.pushSystemTags(entityId, Id.unwrap(tagId));
        SystemTags.pushObjects(tagId, Id.unwrap(entityId));
      } else {
        revert Tag_EntityAlreadyHasTag(entityId, tagId);
      }
    } else {
      revert IEntitySystem.Entity_InvalidEntityType(entityType);
    }
  }

  function _removeSystemTag(Id entityId, Id tagId) private {
    if (!SystemTags.getExists(tagId)) {
      revert Tag_TagDoesNotExist(tagId);
    }

    bytes2 entityType = entityId.getType();
    if (entityType == ENTITY_CLASS) {
      if (!Classes.getExists(entityId)) {
        revert IEntitySystem.Entity_ClassDoesNotExist(entityId);
      }

      ClassSystemTagMapData memory classTagMapData = ClassSystemTagMap.get(entityId, tagId);
      if (classTagMapData.hasTag) {
        Classes.updateSystemTags(
          entityId,
          classTagMapData.tagIndex,
          Classes.getItemSystemTags(entityId, Classes.lengthSystemTags(entityId) - 1)
        );

        SystemTags.updateClasses(
          tagId,
          classTagMapData.classIndex,
          SystemTags.getItemClasses(tagId, SystemTags.lengthClasses(tagId) - 1)
        );

        ClassSystemTagMap.setTagIndex(
          entityId,
          Id.wrap(Classes.getItemSystemTags(entityId, Classes.lengthSystemTags(entityId) - 1)),
          classTagMapData.tagIndex
        );

        ClassSystemTagMap.setClassIndex(
          Id.wrap(SystemTags.getItemClasses(tagId, SystemTags.lengthClasses(tagId) - 1)),
          tagId,
          classTagMapData.classIndex
        );

        ClassSystemTagMap.deleteRecord(entityId, tagId);

        Classes.popSystemTags(entityId);
        SystemTags.popClasses(tagId);
      } else {
        revert Tag_TagNotFound(entityId, tagId);
      }
    } else if (entityType == ENTITY_OBJECT) {
      if (!Objects.getExists(entityId)) {
        revert IEntitySystem.Entity_ObjectDoesNotExist(entityId);
      }

      ObjectSystemTagMapData memory objectTagMapData = ObjectSystemTagMap.get(entityId, tagId);
      if (objectTagMapData.hasTag) {
        Objects.updateSystemTags(
          entityId,
          objectTagMapData.tagIndex,
          Objects.getItemSystemTags(entityId, Objects.lengthSystemTags(entityId) - 1)
        );

        SystemTags.updateObjects(
          tagId,
          objectTagMapData.objectIndex,
          SystemTags.getItemObjects(tagId, SystemTags.lengthObjects(tagId) - 1)
        );

        ObjectSystemTagMap.setTagIndex(
          entityId,
          Id.wrap(Objects.getItemSystemTags(entityId, Objects.lengthSystemTags(entityId) - 1)),
          objectTagMapData.tagIndex
        );

        ObjectSystemTagMap.setObjectIndex(
          Id.wrap(SystemTags.getItemObjects(tagId, SystemTags.lengthObjects(tagId) - 1)),
          tagId,
          objectTagMapData.objectIndex
        );

        ObjectSystemTagMap.deleteRecord(entityId, tagId);

        Objects.popSystemTags(entityId);
        SystemTags.popObjects(tagId);
      } else {
        revert Tag_TagNotFound(entityId, tagId);
      }
    } else {
      revert IEntitySystem.Entity_InvalidEntityType(entityType);
    }
  }
}
