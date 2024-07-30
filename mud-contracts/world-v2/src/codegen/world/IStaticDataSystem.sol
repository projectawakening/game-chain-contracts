// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

/**
 * @title IStaticDataSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IStaticDataSystem {
  function eveworld__createStaticData(uint256 entityId, string memory cid) external;

  function eveworld__createStaticDataMetadata(
    ResourceId systemId,
    string memory name,
    string memory symbol,
    string memory baseURI
  ) external;

  function eveworld__setCid(uint256 entityId, string memory cid) external;

  function eveworld__setName(ResourceId systemId, string memory name) external;

  function eveworld__setSymbol(ResourceId systemId, string memory symbol) external;

  function eveworld__setBaseURI(ResourceId systemId, string memory baseURI) external;
}
