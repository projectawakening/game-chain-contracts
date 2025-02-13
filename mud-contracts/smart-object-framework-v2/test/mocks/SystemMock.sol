// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { SmartObjectFramework } from "../../src/inherit/SmartObjectFramework.sol";
import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { IWorldWithContext } from "../../src/IWorldWithContext.sol";

import { TransientContext } from "./types.sol";

contract SystemMock is SmartObjectFramework {
  // scope testing functions
  function classLevelScope(uint256 classId) public view scope(classId) returns (bool) {
    return true;
  }

  function objectLevelScope(uint256 objectId) public view scope(objectId) returns (bool) {
    return true;
  }

  function entryScoped(uint256 classId, bool taggedCall) public scope(classId) returns (bytes memory) {
    ResourceId TAGGED_SYSTEM_ID = ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("TaggedSystemMock"))))
    );
    ResourceId UNTAGGED_SYSTEM_ID = ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("UnTaggedSystemMo"))))
    );
    if (taggedCall == true) {
      // make a secondary tagged system call (proving that the internal scope enforcement allows fully scoped call chains to pass)
      // tagged system call
      bytes memory callData = abi.encodeCall(this.internalScoped, (classId));
      return IWorldKernel(_world()).call(TAGGED_SYSTEM_ID, callData);
    } else {
      // make an unscoped untagged system call which subsequently calls a scoped tagged system call (proving that call chains which leave scope and try to re-enter are blocked by internal scope enforcement)
      bytes memory callData = abi.encodeCall(this.entryNonScoped, (classId));
      return IWorldKernel(_world()).call(UNTAGGED_SYSTEM_ID, callData);
    }
  }

  function entryNonScoped(uint256 classId) public returns (bytes memory) {
    ResourceId TAGGED_SYSTEM_ID = ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("TaggedSystemMock"))))
    );
    // make a tagged system call
    bytes memory callData = abi.encodeCall(this.internalScoped, (classId));
    return IWorldKernel(_world()).call(TAGGED_SYSTEM_ID, callData);
  }

  function internalScoped(uint256 classId) public view scope(classId) returns (bool) {
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

  function accessControlled(
    uint256 classId,
    ResourceId systemId,
    bytes4 functionId
  ) public enforceCallCount(1) access(classId) returns (ResourceId, bytes4) {
    return (systemId, functionId);
  }
}
