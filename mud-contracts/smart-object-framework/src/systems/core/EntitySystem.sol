// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { EntityTable } from "../../codegen/tables/EntityTable.sol";
import { EntityType } from "../../codegen/tables/EntityType.sol";
import { EntityTypeAssociation } from "../../codegen/tables/EntityTypeAssociation.sol";
import { EntityMap } from "../../codegen/tables/EntityMap.sol";
import { ICustomErrorSystem } from "../../codegen/world/ICustomErrorSystem.sol";
import { EveSystem } from "../internal/EveSystem.sol";
import { INVALID_ID } from "../../constants.sol";

import { Utils } from "../../utils.sol";

/**
 * @title EntitySystem
 * @dev EntitySystem is a system that manages entities such as Classes and objects.
 *
 */
contract EntitySystem is EveSystem {
  using Utils for bytes14;

  // Modifiers
  modifier requireValidEntityId(uint256 entityId) {
    if (entityId == INVALID_ID) revert ICustomErrorSystem.InvalidEntityId();
    _;
  }

  modifier requireEntityTypeExists(uint8 entityType) {
    if (EntityType.getDoesExists(entityType) == false)
      revert ICustomErrorSystem.EntityTypeNotRegistered(entityType, "EntitySystem: EntityType not registered");
    _;
  }

  /**
   * @notice Registers an entity type
   * @param entityTypeId is the id of a entityType
   * @param entityType is the name of the entityType
   */
  function registerEntityType(uint8 entityTypeId, bytes32 entityType) external requireValidEntityId(entityTypeId) {
    _registerEntityType(entityTypeId, entityType);
  }

  /**
   * @notice Registers an entity by its type
   * @param entityId is the id of the entity
   * @param entityType is the type of the entity
   */
  function registerEntity(uint256 entityId, uint8 entityType) external {
    _registerEntity(entityId, entityType);
  }

  /**
   * @notice Overloaded function to register multiple entities
   */
  function registerEntities(uint256[] memory entityId, uint8[] memory entityType) external {
    if (entityId.length != entityType.length)
      revert ICustomErrorSystem.InvalidArrayLength(
        entityId.length,
        entityType.length,
        "EntitySystem: Array length mismatch"
      );
    for (uint256 i = 0; i < entityId.length; i++) {
      _registerEntity(entityId[i], entityType[i]);
    }
  }

  /**
   * @notice Defines an association enforcement between two entity types
   * @param entityType is the id of the entity type
   * @param tagEntityType is the id of the entity type that can be tagged under
   */
  function registerEntityTypeAssociation(
    uint8 entityType,
    uint8 tagEntityType
  )
    external
    requireEntityTypeExists(entityType)
    requireEntityTypeExists(tagEntityType)
    hookable(uint256(entityType), _systemId())
  {
    _registerEntityTypeAssociation(entityType, tagEntityType);
  }

  /**
   * @notice Tags/Groups entities to a another entity
   * @dev Similar Objects can be tagged under a Class and associate modules to the class, so that all the objects under the class can inherit the modules.
   * @param entityId is the id of the entity
   * @param entityTagId is the id of the entity tag which the entity belongs to
   */
  function tagEntity(uint256 entityId, uint256 entityTagId) external hookable(entityId, _systemId()) {
    _tagEntity(entityId, entityTagId);
  }

  /**
   * @notice Overloaded function to tagEntity under multiple entities
   */
  function tagEntities(uint256 entityId, uint256[] memory entityTagIds) external hookable(entityId, _systemId()) {
    for (uint256 i = 0; i < entityTagIds.length; i++) {
      _tagEntity(entityId, entityTagIds[i]);
    }
  }

  /**
   * @notice Removes the entity tag from a entity
   * @param entityId is the id of the entity
   * @param entityTagId is the id of the tagged entity
   */
  function removeEntityTag(uint256 entityId, uint256 entityTagId) external hookable(entityId, _systemId()) {
    _removeEntityTag(entityId, entityTagId);
  }

  function _registerEntityType(uint8 entityTypeId, bytes32 entityType) internal {
    if (EntityType.getDoesExists(entityTypeId) == true)
      revert ICustomErrorSystem.EntityTypeAlreadyRegistered(
        entityTypeId,
        "EntitySystem: EntityType already registered"
      );

    EntityType.set(entityTypeId, true, entityType);
  }

  function _registerEntity(
    uint256 entityId,
    uint8 entityType
  ) internal requireValidEntityId(entityId) requireEntityTypeExists(entityType) {
    if (EntityTable.getDoesExists(entityId) == true)
      revert ICustomErrorSystem.EntityAlreadyRegistered(entityId, "EntitySystem: Entity already registered");

    EntityTable.set(entityId, true, entityType);
  }

  function _registerEntityTypeAssociation(uint8 entityType, uint8 tagEntityType) internal {
    EntityTypeAssociation.set(entityType, tagEntityType, true);
  }

  function _tagEntity(uint256 entityId, uint256 entityTagId) internal {
    _requireEntityRegistered(entityId);
    _requireEntityRegistered(entityTagId);
    _requireAssociationAllowed(entityId, entityTagId);

    uint256[] memory taggedEntities = EntityMap.get(entityId);
    (, bool exists) = findIndex(taggedEntities, entityTagId);
    if (exists)
      revert ICustomErrorSystem.EntityAlreadyTagged(entityId, entityTagId, "EntitySystem: Entity already tagged");

    EntityMap.pushTaggedEntityIds(entityId, entityTagId);
  }

  function _removeEntityTag(uint256 entityId, uint256 entityTagId) internal {
    //TODO Have to figure out a clean way to remove an element from an array
    uint256[] memory taggedEntities = EntityMap.get(entityId);
    (uint256 index, bool exists) = findIndex(taggedEntities, entityTagId);
    if (exists) {
      // Swap the element with the last one and pop the last element
      uint256 lastIndex = taggedEntities.length - 1;
      if (index != lastIndex) {
        EntityMap.update(entityId, index, taggedEntities[lastIndex]);
      }
      EntityMap.pop(entityId);
    }
  }

  function _requireAssociationAllowed(uint256 entityId, uint256 entityTagId) internal view {
    uint8 entityType = EntityTable.getEntityType(entityId);
    uint8 tagEntityType = EntityTable.getEntityType(entityTagId);

    if (EntityTypeAssociation.get(entityType, tagEntityType) == false)
      revert ICustomErrorSystem.EntityTypeAssociationNotAllowed(
        entityType,
        tagEntityType,
        "EntitySystem: EntityType association not allowed"
      );
  }

  function _systemId() internal view returns (ResourceId) {
    return _namespace().entitySystemId();
  }
}
