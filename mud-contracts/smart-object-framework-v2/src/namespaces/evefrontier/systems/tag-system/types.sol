// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { TagId } from "../../../../libs/TagId.sol";

/**
 * @dev Tag Types
 */
bytes2 constant TAG_TYPE_PROPERTY = bytes2("pt");
bytes2 constant TAG_TYPE_ENTITY_RELATION = bytes2("et");
bytes2 constant TAG_TYPE_RESOURCE_RELATION = bytes2("rt");

/**
 * @dev SOF based Property Tag Identifers
 */
bytes30 constant TAG_IDENTIFIER_CLASS = bytes30("CLASS");
bytes30 constant TAG_IDENTIFIER_OBJECT = bytes30("OBJECT");
bytes30 constant TAG_IDENTIFIER_ENTITY_COUNT = bytes30("ENTITY_COUNT");

/**
 * @dev Tag value data structures
 */
struct EntityRelationValue {
  string relationType;
  uint256 relatedEntityId;
}

struct ResourceRelationValue {
  string relationType;
  bytes2 resourceType;
  bytes30 resourceIdentifier;
}

/**
 * @dev Tag input data structure
 */
struct TagParams {
  TagId tagId;
  bytes value;
}
