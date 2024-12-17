// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { LocationData } from "./../../namespaces/evefrontier/codegen/index.sol";

/**
 * @title ILocationSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ILocationSystem {
  function null__saveLocation(uint256 smartObjectId, LocationData memory locationData) external;

  function null__setSolarSystemId(uint256 smartObjectId, uint256 solarSystemId) external;

  function null__setX(uint256 smartObjectId, uint256 x) external;

  function null__setY(uint256 smartObjectId, uint256 y) external;

  function null__setZ(uint256 smartObjectId, uint256 z) external;
}
