// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Id } from "../../../libs/Id.sol";

/**
 * @title ITagSystem
 * @dev An interface for the Tags System functionality
 */
interface ITagSystem {
  function setSystemTag(Id entityId, Id systemTagId) external;
  function setSystemTags(Id entityId, Id[] memory systemTagIds) external;
  function removeSystemTag(Id entityId, Id tagId) external;
  function removeSystemTags(Id entityId, Id[] memory tagIds) external;

  error Tag_InvalidTagId(Id tagId);
  error Tag_InvalidTagType(bytes2 givenType);
  error Tag_TagAlreadyExists(Id tagId);
  error Tag_TagDoesNotExist(Id tagId);
  error Tag_TagNotFound(Id entityId, Id tagId);
  error Tag_WrongTagType(bytes2 givenType, bytes2[] expectedTypes);
  error Tag_SystemNotRegistered(ResourceId systemId);
  error Tag_EntityAlreadyHasTag(Id entityId, Id tagId);
}
