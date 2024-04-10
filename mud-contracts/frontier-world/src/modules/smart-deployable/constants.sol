// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_NAMESPACE } from "@latticexyz/world/src/worldResourceTypes.sol";

uint256 constant FUEL_DECIMALS = 18;

bytes16 constant SMART_DEPLOYABLE_MODULE_NAME = "SmartDeployable";
bytes14 constant SMART_DEPLOYABLE_MODULE_NAMESPACE = "SmartDeployabl";

bytes16 constant GLOBAL_STATE_TABLE_NAME = "GlobalStateTable";
bytes16 constant DEPLOYABLE_STATE_TABLE_NAME = "DeployableTable";
bytes16 constant FUEL_BALANCE_TABLE_NAME = "FuelBalanceTable";
