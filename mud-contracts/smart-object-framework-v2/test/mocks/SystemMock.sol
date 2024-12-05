// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { SmartObjectFramework } from "../../src/inherit/SmartObjectFramework.sol";
import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { IWorldWithContext } from "../../src/IWorldWithContext.sol";
import { Id, IdLib } from "../../src/libs/Id.sol";
import { ENTITY_CLASS } from "../../src/types/entityTypes.sol";

import { TransientContext } from "./types.sol";

contract SystemMock is SmartObjectFramework {
  // scope testing functions
  function classLevelScope(Id classId) public view scope(classId) returns (bool) {
    return true;
  }

  function objectLevelScope(Id objectId) public view scope(objectId) returns (bool) {
    return true;
  }

  function entryScope(Id classId, bool testFlag) public scope(classId) returns (bytes memory) {
    if (testFlag == true) {
      bytes memory callData = abi.encodeCall(this.internalScope, (classId));
      IWorldKernel(_world()).call(SystemRegistry.get(address(this)), callData);
    } else {
      bytes memory callData = abi.encodeCall(this.internalNonScope, (classId));
      IWorldKernel(_world()).call(SystemRegistry.get(address(this)), callData);
    }
  }

  function internalNonScope(Id classId) public returns (bytes memory) {
      bytes memory callData = abi.encodeCall(this.internalScope, (classId));
      IWorldKernel(_world()).call(SystemRegistry.get(address(this)), callData);
  }

  function internalScope(Id classId) public view scope(classId) returns (bool) {
    return true;
  }

  // context testing functions
  function primaryCall() public payable context returns (bytes memory) {
    if (msg.sender != _world()) {
      // cannot receive payments from non-world sources (i.e. activity not delegated through the World contract)
      revert("Cannot receive payments from non-world sources");
    }

    bytes memory callData = abi.encodeCall(this.secondaryCall, ());
    return IWorldKernel(_world()).call(SystemRegistry.get(address(this)), callData);
  }

  function secondaryCall() public context returns (TransientContext memory, TransientContext memory) {
    // transient storage setting to ensure this is not a static call
    uint256 maxSlot = type(uint256).max;
    assembly {
      tstore(maxSlot, 0)
    }

    (ResourceId systemId1, bytes4 functionId1, address msgSender1, uint256 msgValue1) = IWorldWithContext(_world())
      .getWorldCallContext(1);
    (ResourceId systemId2, bytes4 functionId2, address msgSender2, uint256 msgValue2) = IWorldWithContext(_world())
      .getWorldCallContext(2);
    TransientContext memory transientContext1 = TransientContext(systemId1, functionId1, msgSender1, msgValue1);
    TransientContext memory transientContext2 = TransientContext(systemId2, functionId2, msgSender2, msgValue2);
    return (transientContext1, transientContext2);
  }

  function viewCall() public pure returns (bool) {
    return true;
  }

  function callFromWorldContextProviderLib() public returns (bytes memory) {
    ResourceId targetSystemId = WorldResourceIdLib.encode(
      RESOURCE_SYSTEM,
      bytes14("evefrontier"),
      bytes16("TaggedSystemMock")
    );
    address targetAddress = Systems.getSystem(targetSystemId);
    (bool success, bytes memory returnData) = WorldContextProviderLib.callWithContext(
      address(0xbadB0b),
      uint256(999),
      targetAddress,
      abi.encodeCall(this.primaryCall, ())
    );
    if (!success) revertWithBytes(returnData);
    return returnData;
  }

  function delegatecallFromWorldContextProviderLib() public returns (bytes memory) {
    ResourceId targetSystemId = WorldResourceIdLib.encode(
      RESOURCE_SYSTEM,
      bytes14("evefrontier"),
      bytes16("TaggedSystemMock")
    );
    address targetAddress = Systems.getSystem(targetSystemId);
    (bool success, bytes memory returnData) = WorldContextProviderLib.delegatecallWithContext(
      address(0xbadB0b),
      uint256(999),
      targetAddress,
      abi.encodeCall(this.primaryCall, ())
    );
    if (!success) revertWithBytes(returnData);
    return returnData;
  }

  // enforceCallCount testing functions
  function callToEnforceCallCount1() public {
    IWorldKernel(_world()).call(
      SystemRegistry.get(address(this)),
      abi.encodePacked(this.callEnforceCallCount1.selector)
    );
  }

  function callEnforceCallCount1() public enforceCallCount(1) returns (bool) {
    // transient storage setting to ensure this is not a static call
    uint256 maxSlot = type(uint256).max;
    assembly {
      tstore(maxSlot, 0)
    }

    return true;
  }

  function accessControlled(Id classId, ResourceId systemId, bytes4 functionId) public enforceCallCount(1) access(classId) returns (bool) {
    return true;
  }

}
