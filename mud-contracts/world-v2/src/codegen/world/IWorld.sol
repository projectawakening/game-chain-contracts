// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { IEveSystem } from "./IEveSystem.sol";
import { IAccessSystem } from "./IAccessSystem.sol";
import { IDeployableSystem } from "./IDeployableSystem.sol";
import { IEntityRecordSystem } from "./IEntityRecordSystem.sol";
import { IERC721System } from "./IERC721System.sol";
import { IFuelSystem } from "./IFuelSystem.sol";
import { IEphemeralInventorySystem } from "./IEphemeralInventorySystem.sol";
import { IInventoryInteractSystem } from "./IInventoryInteractSystem.sol";
import { IInventorySystem } from "./IInventorySystem.sol";
import { ILocationSystem } from "./ILocationSystem.sol";
import { ISmartAssemblySystem } from "./ISmartAssemblySystem.sol";
import { ISmartCharacterSystem } from "./ISmartCharacterSystem.sol";
import { ISmartGateSystem } from "./ISmartGateSystem.sol";
import { ISmartStorageUnitSystem } from "./ISmartStorageUnitSystem.sol";
import { ISmartTurretSystem } from "./ISmartTurretSystem.sol";
import { IStaticDataSystem } from "./IStaticDataSystem.sol";

/**
 * @title IWorld
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @notice This interface integrates all systems and associated function selectors
 * that are dynamically registered in the World during deployment.
 * @dev This is an autogenerated file; do not edit manually.
 */
interface IWorld is
  IBaseWorld,
  IEveSystem,
  IAccessSystem,
  IDeployableSystem,
  IEntityRecordSystem,
  IERC721System,
  IFuelSystem,
  IEphemeralInventorySystem,
  IInventoryInteractSystem,
  IInventorySystem,
  ILocationSystem,
  ISmartAssemblySystem,
  ISmartCharacterSystem,
  ISmartGateSystem,
  ISmartStorageUnitSystem,
  ISmartTurretSystem,
  IStaticDataSystem
{}
