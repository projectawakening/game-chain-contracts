// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title TagId type definition and related utilities
 * @author CCP Games (inspired by the Lattice teams's ResourceId type definition)
 * @dev A TagId is a bytes32 data structure that consists of a bytes2 tag type and a bytes30 tag identifier
 * shared type and a unique identifier
 */
type TagId is bytes32;

using TagIdInstance for TagId global;

/// @dev Number of bits reserved for the type in the ID.
uint256 constant TYPE_BITS = 2 * 8; // 2 bytes * 8 bits per byte

/**
 * @title TagIdLib Library
 * @author CCP Games (inspired by the Lattice team's ResourceId.sol and accompanying libraries)
 * @dev Provides functions to encode data into a TagId
 */
library TagIdLib {
  /**
   * @notice Encodes given type and identifier into a TagId.
   * @param typeId The shared type to be encoded. Must be 2 bytes.
   * @param identifier The unique identifier to be encoded. Must be 30 bytes.
   * @return A TagId containing the encoded type and identifier.
   */
  function encode(bytes2 typeId, bytes30 identifier) internal pure returns (TagId) {
    return TagId.wrap(bytes32(typeId) | (bytes32(identifier) >> TYPE_BITS));
  }
}

/**
 * @title TagId Instance Library
 * @author CCP Games (inspired by the Lattice team's ResourceIdInstance)
 * @dev Provides functions to extract data from a TagId.
 */
library TagIdInstance {
  /**
   * @notice Extracts the shared type from a given TagId.
   * @param id The TagId from which the type should be extracted.
   * @return The extracted 2-byte type.
   */
  function getType(TagId id) internal pure returns (bytes2) {
    return bytes2(TagId.unwrap(id));
  }

  /**
   * @notice Get the unique indentifier bytes from an TagId.
   * @param id The TagId.
   * @return the extracted 30-bytes unique identifier.
   */
  function getIdentifier(TagId id) internal pure returns (bytes30) {
    return bytes30(TagId.unwrap(id) << (TYPE_BITS));
  }
}
