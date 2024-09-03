// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { EveSystem } from "@eveworld/smart-object-framework/src/systems/internal/EveSystem.sol";
import { SmartObjectLib } from "@eveworld/smart-object-framework/src/SmartObjectLib.sol";
import { Utils as SmartObjectFrameworkUtils } from "@eveworld/smart-object-framework/src/utils.sol";
import { EntityTable } from "@eveworld/smart-object-framework/src/codegen/tables/EntityTable.sol";
import { ENTITY_RECORD_DEPLOYMENT_NAMESPACE, SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE, SMART_OBJECT_DEPLOYMENT_NAMESPACE, OBJECT } from "@eveworld/common-constants/src/constants.sol";

import { SmartGateConfigTable } from "../../../codegen/tables/SmartGateConfigTable.sol";
import { GlobalDeployableState } from "../../../codegen/tables/GlobalDeployableState.sol";
import { DeployableState, DeployableStateData } from "../../../codegen/tables/DeployableState.sol";
import { LocationTableData } from "../../../codegen/tables/LocationTable.sol";
import { ClassConfig } from "../../../codegen/tables/ClassConfig.sol";
import { SmartGateLinkTable } from "../../../codegen/tables/SmartGateLinkTable.sol";
import { State, SmartAssemblyType } from "../../../codegen/common.sol";

import { EntityRecordData, WorldPosition } from "../../smart-storage-unit/types.sol";
import { EntityRecordLib } from "../../entity-record/EntityRecordLib.sol";

import { SmartDeployableErrors } from "../../smart-deployable/SmartDeployableErrors.sol";
import { SmartDeployableLib } from "../../smart-deployable/SmartDeployableLib.sol";
import { SmartDeployableLib } from "../../smart-deployable/SmartDeployableLib.sol";
import { SmartObjectData } from "../../smart-deployable/types.sol";
import { Utils as SmartDeployableUtils } from "../../smart-deployable/Utils.sol";
import { AccessModified } from "../../access/systems/AccessModified.sol";

import { Utils } from "../Utils.sol";

/**
 * @title SmartGate
 * @notice Smart Gate module
 */
contract SmartGate is EveSystem, AccessModified {
  using WorldResourceIdInstance for ResourceId;
  using SmartObjectLib for SmartObjectLib.World;
  using EntityRecordLib for EntityRecordLib.World;
  using SmartDeployableLib for SmartDeployableLib.World;
  using SmartObjectFrameworkUtils for bytes14;
  using SmartDeployableUtils for bytes14;
  using Utils for bytes14;

  error SmartGate_UndefinedClassId();
  error SmartGate_NotConfigured(uint256 smartGateId);
  error SmartGate_GateAlreadyLinked(uint256 sourceGateId, uint256 destinationGateId);
  error SmartGate_GateNotLinked(uint256 sourceGateId, uint256 destinationGateId);

  /**
   * modifier to enforce state changes can happen only when the game server is running
   */
  modifier onlyActive() {
    if (GlobalDeployableState.getIsPaused(_namespace().globalStateTableId()) == false) {
      revert SmartDeployableErrors.SmartDeployable_StateTransitionPaused();
    }
    _;
  }

  /**
    * @notice Create and anchor a Smart Turret
    * @param smartGateId is smart object id of the Smart Turret
    * @param entityRecordData is the entity record data of the Smart Turret
    * @param smartObjectData is the metadata of the Smart Turret
    * @param worldPosition is the x,y,z position of the Smart Turret in space
    * @param fuelUnitVolume is the volume of fuel unit
    * @param fuelConsumptionIntervalInSeconds is one unit of fuel consumption interval is consumed in how many seconds
    // For example:
    // OneFuelUnitConsumptionIntervalInSec = 1; // Consuming 1 unit of fuel every second.
    // OneFuelUnitConsumptionIntervalInSec = 60; // Consuming 1 unit of fuel every minute.
    // OneFuelUnitConsumptionIntervalInSec = 3600; // Consuming 1 unit of fuel every hour.
    * @param fuelMaxCapacity is the maximum capacity of fuel
   */
  function createAndAnchorSmartGate(
    uint256 smartGateId,
    EntityRecordData memory entityRecordData,
    SmartObjectData memory smartObjectData,
    WorldPosition memory worldPosition,
    uint256 fuelUnitVolume,
    uint256 fuelConsumptionIntervalInSeconds,
    uint256 fuelMaxCapacity,
    uint256 maxDistance
  ) public onlyAdmin {
    //Implement the logic to store the data in different modules: EntityRecord, Deployable, Location and ERC721
    _entityRecordLib().createEntityRecord(
      smartGateId,
      entityRecordData.itemId,
      entityRecordData.typeId,
      entityRecordData.volume
    );

    _smartDeployableLib().registerDeployable(
      smartGateId,
      smartObjectData,
      fuelUnitVolume,
      fuelConsumptionIntervalInSeconds,
      fuelMaxCapacity
    );
    _smartDeployableLib().setSmartAssemblyType(smartGateId, SmartAssemblyType.SMART_GATE);

    LocationTableData memory locationData = LocationTableData({
      solarSystemId: worldPosition.solarSystemId,
      x: worldPosition.position.x,
      y: worldPosition.position.y,
      z: worldPosition.position.z
    });
    _smartDeployableLib().anchor(smartGateId, locationData);

    SmartGateConfigTable.setMaxDistance(_namespace().smartGateConfigTableId(), smartGateId, maxDistance);
  }

  /**
   * @notice Link Smart Gates
   * @param sourceGateId is the id of the source gate
   * @param destinationGateId is the id of the destination gate
   */
  function linkSmartGates(uint256 sourceGateId, uint256 destinationGateId) public {
    if (isGateLinked(sourceGateId, destinationGateId)) {
      revert SmartGate_GateAlreadyLinked(sourceGateId, destinationGateId);
    }

    //TODO: Check if the state is online for both the gates ??
    //TODO: Link the gates only when the distance between 2 gates are less than the max distance
    SmartGateLinkTable.set(_namespace().smartGateLinkTableId(), sourceGateId, destinationGateId, true);
  }

  /**
   * @notice Unlink Smart Gates
   * @param sourceGateId is the id of the source gate
   * @param destinationGateId is the id of the destination gate
   */
  function unlinkSmartGates(uint256 sourceGateId, uint256 destinationGateId) public {
    //Check if the gates are linked
    if (!isGateLinked(sourceGateId, destinationGateId)) {
      revert SmartGate_GateNotLinked(sourceGateId, destinationGateId);
    }
    SmartGateLinkTable.set(_namespace().smartGateLinkTableId(), sourceGateId, destinationGateId, false);
  }

  /**
   * @notice Configure Smart Turret
   * @param smartGateId is smart object id of the Smart Turret
   * @param systemId is the system id of the Smart Turret logic
   */
  function configureSmartGate(
    uint256 smartGateId,
    ResourceId systemId
  ) public onlyAdminOrObjectOwner(smartGateId) hookable(smartGateId, _systemId()) {
    SmartGateConfigTable.setSystemId(_namespace().smartGateConfigTableId(), smartGateId, systemId);
  }

  /**
   * @notice view function for smart gates which is linked
   * @param characterId is of the id of the character
   * @param sourceGateId is the id of the source gate
   * @param destinationGateId is the id of the destination gate
   */
  function canJump(uint256 characterId, uint256 sourceGateId, uint256 destinationGateId) public returns (bool) {
    State sourceGateState = DeployableState.getCurrentState(_namespace().deployableStateTableId(), sourceGateId);

    State destinationGateState = DeployableState.getCurrentState(
      _namespace().deployableStateTableId(),
      destinationGateId
    );

    if (sourceGateState != State.ONLINE) {
      revert SmartDeployableErrors.SmartDeployable_IncorrectState(sourceGateId, sourceGateState);
    }

    if (destinationGateState != State.ONLINE) {
      revert SmartDeployableErrors.SmartDeployable_IncorrectState(destinationGateId, destinationGateState);
    }

    //Check if the gates are linked
    if (!isGateLinked(sourceGateId, destinationGateId)) {
      revert SmartGate_GateNotLinked(sourceGateId, destinationGateId);
    }

    ResourceId systemId = SmartGateConfigTable.getSystemId(_namespace().smartGateConfigTableId(), sourceGateId);

    if (ResourceIds.getExists(systemId)) {
      bytes memory returnData = world().call(
        systemId,
        abi.encodeCall(this.canJump, (characterId, sourceGateId, destinationGateId))
      );
      return abi.decode(returnData, (bool));
    }
    return true;
  }

  function isGateLinked(uint256 sourceGateId, uint256 destinationGateId) public view returns (bool) {
    return (
      (SmartGateLinkTable.getIsLinked(_namespace().smartGateLinkTableId(), sourceGateId, destinationGateId)) ||
        (SmartGateLinkTable.getIsLinked(_namespace().smartGateLinkTableId(), destinationGateId, sourceGateId))
        ? true
        : false
    );
  }

  function calculatDistance(uint256 sourceGateId, uint256 destinationGateId) public view returns (uint256) {
    // Implement the logic to calculate the distance between two gates
    uint256 distance = 0;
    return distance;
  }

  function _entityRecordLib() internal view returns (EntityRecordLib.World memory) {
    return EntityRecordLib.World({ iface: IBaseWorld(_world()), namespace: ENTITY_RECORD_DEPLOYMENT_NAMESPACE });
  }

  function _smartDeployableLib() internal view returns (SmartDeployableLib.World memory) {
    return SmartDeployableLib.World({ iface: IBaseWorld(_world()), namespace: SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE });
  }

  function _smartObjectLib() internal view returns (SmartObjectLib.World memory) {
    return SmartObjectLib.World({ iface: IBaseWorld(_world()), namespace: SMART_OBJECT_DEPLOYMENT_NAMESPACE });
  }

  function _systemId() internal view returns (ResourceId) {
    return _namespace().smartGateSystemId();
  }
}
