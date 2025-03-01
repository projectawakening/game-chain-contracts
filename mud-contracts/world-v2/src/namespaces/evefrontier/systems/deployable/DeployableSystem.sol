// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";

import { GlobalDeployableState, GlobalDeployableStateData } from "../../codegen/index.sol";
import { DeployableState, DeployableStateData } from "../../codegen/index.sol";
import { CharactersByAddress } from "../../codegen/index.sol";
import { DeployableToken } from "../../codegen/index.sol";
import { FuelSystem } from "../fuel/FuelSystem.sol";
import { Fuel, FuelData } from "../../codegen/index.sol";
import { LocationSystem } from "../location/LocationSystem.sol";
import { LocationData } from "../../codegen/tables/Location.sol";
import { Location, LocationData } from "../../codegen/index.sol";
import { IERC721Mintable } from "../eve-erc721-puppet/IERC721Mintable.sol";
import { StaticDataSystem } from "../static-data/StaticDataSystem.sol";
import { SmartAssemblySystem } from "../smart-assembly/SmartAssemblySystem.sol";
import { LocationSystemLib, locationSystem } from "../../codegen/systems/LocationSystemLib.sol";
import { StaticDataSystemLib, staticDataSystem } from "../../codegen/systems/StaticDataSystemLib.sol";
import { SmartAssemblySystemLib, smartAssemblySystem } from "../../codegen/systems/SmartAssemblySystemLib.sol";
import { FuelSystemLib, fuelSystem } from "../../codegen/systems/FuelSystemLib.sol";
import { EntityRecordData } from "../entity-record/types.sol";

import { State, SmartObjectData, CreateAndAnchorDeployableParams } from "./types.sol";
import { DECIMALS, ONE_UNIT_IN_WEI } from "./../constants.sol";

/**
 * @title DeployableSystem
 * @author CCP Games
 * DeployableSystem stores the deployable state of a smart object on-chain
 */

contract DeployableSystem is SmartObjectFramework {
  error Deployable_IncorrectState(uint256 smartObjectId, State currentState);
  error Deployable_NoFuel(uint256 smartObjectId);
  error Deployable_StateTransitionPaused();
  error Deployable_TooMuchFuelDeposited(uint256 smartObjectId, uint256 amountDeposited);
  error DeployableERC721AlreadyInitialized();
  error Deployable_InvalidFuelConsumptionInterval(uint256 smartObjectId);
  error Deployable_InvalidObjectOwner(string message, address smartObjectOwner, uint256 smartObjectId);

  /**
   * modifier to enforce deployable state changes can happen only when the game server is running
   */
  modifier onlyActive() {
    if (GlobalDeployableState.getIsPaused() == false) {
      revert Deployable_StateTransitionPaused();
    }
    _;
  }

  /**
   * @dev creates and anchors a deployable
   * @param params struct containing all parameters for creating and anchoring a deployable
   */
  function createAndAnchorDeployable(
    CreateAndAnchorDeployableParams memory params
  ) public context access(params.smartObjectId) scope(params.smartObjectId) {
    smartAssemblySystem.createSmartAssembly(params.smartObjectId, params.smartAssemblyType, params.entityRecordData);

    registerDeployable(
      params.smartObjectId,
      params.smartObjectData,
      params.fuelUnitVolume,
      params.fuelConsumptionIntervalInSeconds,
      params.fuelMaxCapacity
    );
    anchor(params.smartObjectId, params.locationData);
  }

  /**
   * @dev sets the ERC721 address for a deployable token
   * @param erc721Address the address of the ERC721 contract
   */
  function registerDeployableToken(address erc721Address) public context access(0) scope(0) {
    if (DeployableToken.getErc721Address() != address(0)) {
      revert DeployableERC721AlreadyInitialized();
    }
    DeployableToken.set(erc721Address);
  }

  /**
   * TODO: restrict this to smartObjectIds that exist
   * @dev registers a new smart deployable (must be "NULL" state)
   * @param smartObjectId on-chain id of the in-game deployable
   * @param smartObjectData the data of the smart object
   * @param fuelUnitVolume the fuel unit volume in wei
   * @param fuelConsumptionIntervalInSeconds the fuel consumption per minute in wei
   * @param fuelMaxCapacity the fuel max capacity in wei
   */
  function registerDeployable(
    uint256 smartObjectId,
    SmartObjectData memory smartObjectData,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity
  ) public onlyActive context access(smartObjectId) scope(smartObjectId) {
    State previousState = DeployableState.getCurrentState(smartObjectId);
    if (!(previousState == State.NULL || previousState == State.UNANCHORED)) {
      revert Deployable_IncorrectState(smartObjectId, previousState);
    }

    if (fuelConsumptionIntervalInSeconds < 1) {
      revert Deployable_InvalidFuelConsumptionInterval(smartObjectId);
    }

    // revert if the given smart object owner is not a valid character
    if (CharactersByAddress.get(smartObjectData.owner) == 0) {
      revert Deployable_InvalidObjectOwner(
        "SmartDeployableSystem: Smart Object owner is not a valid Smart Character",
        smartObjectData.owner,
        smartObjectId
      );
    }

    if (previousState == State.NULL) {
      address erc721Address = DeployableToken.getErc721Address();
      IERC721Mintable(erc721Address).mint(smartObjectData.owner, smartObjectId);

      staticDataSystem.setCid(smartObjectId, smartObjectData.tokenURI);
    }

    DeployableState.set(
      smartObjectId,
      block.timestamp,
      State.NULL,
      State.UNANCHORED,
      false,
      0,
      block.number,
      block.timestamp
    );

    fuelSystem.configureFuelParameters(
      smartObjectId,
      fuelUnitVolume,
      fuelConsumptionIntervalInSeconds,
      fuelMaxCapacity,
      0
    );
  }

  /**
   * @dev destroys a smart deployable
   * @param smartObjectId on-chain id of the in-game deployable
   */
  function destroyDeployable(
    uint256 smartObjectId
  ) public onlyActive context access(smartObjectId) scope(smartObjectId) {
    State previousState = DeployableState.getCurrentState(smartObjectId);
    if (!(previousState == State.ANCHORED || previousState == State.ONLINE)) {
      revert Deployable_IncorrectState(smartObjectId, previousState);
    }
    _setDeployableState(smartObjectId, previousState, State.DESTROYED);
    DeployableState.setIsValid(smartObjectId, false);
  }

  /**
   * @dev brings a smart deployable online
   * @param smartObjectId of the deployable
   */
  function bringOnline(uint256 smartObjectId) public onlyActive context access(smartObjectId) scope(smartObjectId) {
    State previousState = DeployableState.getCurrentState(smartObjectId);
    if (previousState != State.ANCHORED) {
      revert Deployable_IncorrectState(smartObjectId, previousState);
    }

    fuelSystem.updateFuel(smartObjectId);

    uint256 currentFuel = Fuel.getFuelAmount(smartObjectId);
    if (currentFuel < ONE_UNIT_IN_WEI) revert Deployable_NoFuel(smartObjectId);

    fuelSystem.setFuelAmount(smartObjectId, currentFuel - ONE_UNIT_IN_WEI);

    _setDeployableState(smartObjectId, previousState, State.ONLINE);
  }

  /**
   * @dev brings a smart deployable offline
   * @param smartObjectId id of the deployable
   */
  function bringOffline(uint256 smartObjectId) public onlyActive context access(smartObjectId) scope(smartObjectId) {
    State previousState = DeployableState.getCurrentState(smartObjectId);
    if (previousState != State.ONLINE) {
      revert Deployable_IncorrectState(smartObjectId, previousState);
    }

    fuelSystem.updateFuel(smartObjectId);
    _bringOffline(smartObjectId, previousState);
  }

  /**
   * @dev anchors a smart deployable
   * @param smartObjectId on-chain of the deployable
   * @param locationData the location data of the object
   */
  function anchor(
    uint256 smartObjectId,
    LocationData memory locationData
  ) public onlyActive context access(smartObjectId) scope(smartObjectId) {
    State previousState = DeployableState.getCurrentState(smartObjectId);
    if (previousState != State.UNANCHORED) {
      revert Deployable_IncorrectState(smartObjectId, previousState);
    }
    _setDeployableState(smartObjectId, previousState, State.ANCHORED);

    locationSystem.saveLocation(smartObjectId, locationData);

    DeployableState.setIsValid(smartObjectId, true);
    DeployableState.setAnchoredAt(smartObjectId, block.timestamp);
  }

  /**
   * @dev unanchors a smart deployable
   * @param smartObjectId on-chain of the deployable
   */
  function unanchor(uint256 smartObjectId) public onlyActive context access(smartObjectId) scope(smartObjectId) {
    State previousState = DeployableState.getCurrentState(smartObjectId);
    if (!(previousState == State.ANCHORED || previousState == State.ONLINE)) {
      revert Deployable_IncorrectState(smartObjectId, previousState);
    }

    _setDeployableState(smartObjectId, previousState, State.UNANCHORED);

    locationSystem.saveLocation(smartObjectId, LocationData({ solarSystemId: 0, x: 0, y: 0, z: 0 }));

    DeployableState.setIsValid(smartObjectId, false);
  }

  /**
   * @dev brings all smart deployables online
   * TODO: limit to admin use only
   */
  function globalPause() public context access(0) scope(0) {
    GlobalDeployableState.setIsPaused(false);
    GlobalDeployableState.setUpdatedBlockNumber(block.number);
    GlobalDeployableState.setLastGlobalOffline(block.timestamp);
  }

  /**
   * @dev brings all smart deployables offline
   * TODO: limit to admin use only
   */
  function globalResume() public context access(0) scope(0) {
    GlobalDeployableState.setIsPaused(true);
    GlobalDeployableState.setUpdatedBlockNumber(block.number);
    GlobalDeployableState.setLastGlobalOnline(block.timestamp);
  }

  /*******************************
   * INTERNAL DEPLOYABLE METHODS *
   *******************************/

  /**
   * @dev brings offline smart deployable (internal method)
   * @param smartObjectId on-chain of the deployable
   */
  function _bringOffline(uint256 smartObjectId, State previousState) internal {
    _setDeployableState(smartObjectId, previousState, State.ANCHORED);
  }

  /**
   * @dev internal method to set the state of a deployable
   * @param smartObjectId to update
   * @param previousState to set
   * @param currentState to set
   */
  function _setDeployableState(uint256 smartObjectId, State previousState, State currentState) internal {
    DeployableState.setPreviousState(smartObjectId, previousState);
    DeployableState.setCurrentState(smartObjectId, currentState);
    _updateBlockInfo(smartObjectId);
  }

  /**
   * @dev update block information for a given entity
   * @param smartObjectId to update
   */
  function _updateBlockInfo(uint256 smartObjectId) internal {
    DeployableState.setUpdatedBlockNumber(smartObjectId, block.number);
    DeployableState.setUpdatedBlockTime(smartObjectId, block.timestamp);
  }
}
