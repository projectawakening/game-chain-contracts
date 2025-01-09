// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

// Import user types
// State: {NULL, UNANCHORED, ANCHORED, ONLINE, DESTROYED}
// defined in `mud.config.ts`
import { State } from "../../../../codegen/common.sol";
import { LocationData } from "../../codegen/tables/Location.sol";
import { EntityRecordData } from "../entity-record/types.sol";

/**
 * @notice Holds the data for a smart object
 * @dev SmartObjectData structure
 */
struct SmartObjectData {
  address owner;
  string tokenURI;
}

struct CreateAndAnchorDeployableParams {
  uint256 smartObjectId;
  string smartAssemblyType;
  EntityRecordData entityRecordData;
  SmartObjectData smartObjectData;
  uint256 fuelUnitVolume;
  uint256 fuelConsumptionIntervalInSeconds;
  uint256 fuelMaxCapacity;
  LocationData locationData;
}
