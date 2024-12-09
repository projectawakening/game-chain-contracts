// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;


import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { IEntitySystem } from "../../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { Utils as EntitySystemUtils } from "../../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { ITagSystem } from "../../src/namespaces/evefrontier/interfaces/ITagSystem.sol";
import { Utils as TagSystemUtils } from "../../src/namespaces/evefrontier/systems/tag-system/Utils.sol";

import { Id } from "../../src/libs/Id.sol";

import { SmartObjectFramework } from "../../src/inherit/SmartObjectFramework.sol";

contract UnscopedMock is SmartObjectFramework {
  ResourceId ENTITY_SYSTEM_ID = EntitySystemUtils.entitySystemId();
  ResourceId TAG_SYSTEM_ID = TagSystemUtils.tagSystemId();
  function callSetSystemTag(Id entityId, Id tagId) public {
    IWorldKernel(_world()).call(
      TAG_SYSTEM_ID,
      abi.encodeCall(ITagSystem.setSystemTag, (entityId, tagId))
    );
  }

  function callRemoveSystemTag(Id entityId, Id tagId) public {
    IWorldKernel(_world()).call(
      TAG_SYSTEM_ID,
      abi.encodeCall(ITagSystem.removeSystemTag, (entityId, tagId))
    );
  }

  function callSetClassAccessRole(Id classId, bytes32 newAccessRole) public {
    IWorldKernel(_world()).call(
      ENTITY_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.setClassAccessRole, (classId, newAccessRole))
    );
  }

  function callSetObjectAccessRole(Id objectId, bytes32 newAccessRole) public {
    IWorldKernel(_world()).call(
      ENTITY_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.setObjectAccessRole, (objectId, newAccessRole))
    );
  }

  function callInstantiate(Id classId, Id objectId) public {
    IWorldKernel(_world()).call(
      ENTITY_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.instantiate, (classId, objectId))
    );
  }

  function callDeleteObject(Id objectId) public {
    IWorldKernel(_world()).call(
      ENTITY_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.deleteObject, (objectId))
    );
  }

}