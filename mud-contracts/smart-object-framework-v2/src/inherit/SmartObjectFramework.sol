// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";

import { Id } from "../libs/Id.sol";
import { Bytes } from "../libs/Bytes.sol";

import { TAG_SYSTEM } from "../types/tagTypes.sol";
import { ENTITY_CLASS, ENTITY_OBJECT } from "../types/entityTypes.sol";

import { Objects } from "../namespaces/evefrontier/codegen/tables/Objects.sol";
import { ClassSystemTagMap } from "../namespaces/evefrontier/codegen/tables/ClassSystemTagMap.sol";
import { ObjectSystemTagMap } from "../namespaces/evefrontier/codegen/tables/ObjectSystemTagMap.sol";
import { AccessConfigData, AccessConfig } from "../namespaces/evefrontier/codegen/tables/AccessConfig.sol";

import { IEntitySystem } from "../namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { ITagSystem } from "../namespaces/evefrontier/interfaces/ITagSystem.sol";

import { IWorldWithContext } from "../IWorldWithContext.sol";

/**
 * @title SmartObjectFramework
 * @author CCP Games
 * @dev Base contract that extends MUD System with Smart Object Framework functionality
 * @dev Provides execution context enforcement, entity-to-system scoping, and context parameter access for SOF systems
 */
contract SmartObjectFramework is System {
  /// @notice Thrown when a system call is made outside proper context
  error SOF_InvalidCall();

  /**
   * @notice Thrown when a system call is made outside the configured scope for an entity
   * @param entityId The entity ID that was checked
   * @param systemId The system ID that was called
   */
  error SOF_UnscopedSystemCall(Id entityId, ResourceId systemId);

  /**
   * @notice Thrown when an invalid entity type is passed to the scope() modifier
   * @param givenType The given incorrect entity type data
   */
  error SOF_InvalidEntityType(bytes2 givenType);

  /**
   * @notice Thrown when a system call beyond a prohibited depth is made
   * @param callCount The callCount at the time of reverting
   */
  error SOF_CallTooDeep(uint256 callCount);
  
  /**
   * @notice Thrown when access logic mutates state
   */
  error SOF_InvalidAccessLogic();

  /// @notice Size of MUD context data appended to calls (address + uint256)
  uint256 constant MUD_CONTEXT_BYTES = 20 + 32;

  /**
   * @notice Enforces proper execution context for system calls
   * @dev Verifies the calling system and function selector match tracked context
   */
  modifier context() {
    ResourceId systemId = SystemRegistry.get(address(this));
    _contextGuard(systemId);
    _;
  }

  /**
   * @notice Enforces entity-based system accessibility scope
   * @dev Checks if system can operate on given entity based on class tags
   * @param entityId The entity ID to check scope fo
   */
  modifier scope(Id entityId) {
    // check that the current system is in scope for the given entity
    ResourceId systemId = SystemRegistry.get(address(this));
    _scope(entityId, systemId);
    // if this is a subsequent system-to-system call (callCount > 1), then check that the previous (calling) system is in scope for the given entity
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    if (callCount > 1) {
      (ResourceId prevSystemId, , , ) = IWorldWithContext(_world()).getWorldCallContext(
        callCount - 1
      );
      _scope(entityId, prevSystemId);
    }
    _;
  }

  modifier access(Id entityId) {
    bytes32 target = keccak256(abi.encodePacked(SystemRegistry.get(address(this)), msg.sig));
    _access(entityId, target);
    _;
  }

  modifier enforceCallCount(uint256 maxCallCount) {
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    _enforceMaxCallCount(callCount, maxCallCount);
    _;
  }

  /**
   * @notice Validates that the current execution context matches the expected system and function
   * @dev Compares the current system ID and function selector against the tracked context
   */
  function _contextGuard(ResourceId systemId) internal view {
    (ResourceId trackedSystemId, bytes4 trackedFunctionSelector, , ) = IWorldWithContext(_world()).getWorldCallContext(
      IWorldWithContext(_world()).getWorldCallCount()
    );
    if (
      ResourceId.unwrap(systemId) != ResourceId.unwrap(trackedSystemId) || bytes4(msg.data) != trackedFunctionSelector
    ) {
      revert SOF_InvalidCall();
    }
  }

  /**
   * @notice Gets the tracked msg.sender from the current world call context
   * @dev Retrieves msg.sender for the latest call in the world execution context stack
   * @return address The tracked msg.sender address
   */
  function _callMsgSender() internal view returns (address) {
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(
      IWorldWithContext(_world()).getWorldCallCount()
    );
    return msgSender;
  }

  /**
   * @notice Gets the tracked msg.sender for a specific world call context
   * @dev Retrieves msg.sender for the specified call count in the world execution context stack
   * @param callCount The specific call count to get the call context for
   * @return address The tracked msg.sender address for a world call
   */
  function _callMsgSender(uint256 callCount) internal view returns (address) {
    (, , address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    return msgSender;
  }

  /**
   * @notice Gets the tracked msg.value for the current world call context
   * @dev Retrieves msg.value for the latest call in the world execution context stack
   * @return uint256 The tracked msg.value amount
   */
  function _callMsgValue() internal view returns (uint256) {
    (, , , uint256 msgValue) = IWorldWithContext(_world()).getWorldCallContext(
      IWorldWithContext(_world()).getWorldCallCount()
    );
    return msgValue;
  }

  /**
   * @notice Gets the tracked msg.value for a specific world call context
   * @dev Retrieves msg.value for the specified call count in the world execution context stack
   * @param callCount The specific call count to get the context for
   * @return uint256 The tracked msg.value amount for that call
   */
  function _callMsgValue(uint256 callCount) internal view returns (uint256) {
    (, , , uint256 msgValue) = IWorldWithContext(_world()).getWorldCallContext(callCount);
    return msgValue;
  }

  /**
   * @notice Removes the MUD context bytes from the end of calldata
   * @dev Slices off the trailing context bytes (address + uint256) from the provided calldata
   * @param callDataWithContext The original calldata including MUD context
   * @return bytes The calldata with context bytes removed
   */
  function _callDataWithoutContext(bytes memory callDataWithContext) internal pure returns (bytes memory) {
    return Bytes.slice(callDataWithContext, 0, callDataWithContext.length - MUD_CONTEXT_BYTES);
  }

  function _scope(Id entityId, ResourceId systemId) internal virtual view {
    if (Id.unwrap(entityId) != bytes32(0)) {
      bool classHasTag;
      if (entityId.getType() == ENTITY_CLASS) {
        classHasTag = ClassSystemTagMap.getHasTag(entityId, Id.wrap(ResourceId.unwrap(systemId)));
        if (!classHasTag) {
          revert SOF_UnscopedSystemCall(entityId, systemId);
        }
      } else if (entityId.getType() == ENTITY_OBJECT) {
        Id classId = Objects.getClass(entityId);
        classHasTag = ClassSystemTagMap.getHasTag(classId, Id.wrap(ResourceId.unwrap(systemId)));
        bool objectHasTag = ObjectSystemTagMap.getHasTag(entityId, Id.wrap(ResourceId.unwrap(systemId)));
        if (!(classHasTag || objectHasTag)) {
          revert SOF_UnscopedSystemCall(entityId, systemId);
        }
      } else {
        revert SOF_InvalidEntityType(entityId.getType());
      }
    }
  }

  function _access(Id entityId, bytes32 target) internal view virtual {
    AccessConfigData memory accessConfig = AccessConfig.get(target);
    // target function selector is 4 bytes, _msgSender is 20 bytes, _msgValue is 32 bytes = 56
    bytes memory callData = Bytes.slice(msg.data, 4, msg.data.length - 56);

    if(accessConfig.configured && accessConfig.enforcement) {
      // console.log("HERE");
      IWorldWithContext(_world()).callStatic(
        accessConfig.accessSystemId, 
        abi.encodeWithSelector(accessConfig.accessFunctionId, entityId, callData)
      );
    }
  }

  function _enforceMaxCallCount(uint256 callCount, uint256 maxCallCount) internal virtual view {
    if (callCount > maxCallCount) {
      revert SOF_CallTooDeep(callCount);
    }
  }
}
