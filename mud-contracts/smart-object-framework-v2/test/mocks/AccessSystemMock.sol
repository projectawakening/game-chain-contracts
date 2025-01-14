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

import { SystemMock } from "./SystemMock.sol";

contract AccessSystemMock is SmartObjectFramework {
  error AccessSystemMock_IncorrectEntityId(uint256 entityId, uint256 classId);
  error AccessSystemMock_IncorrectCallData();
  error AccessSystemMock_IncorrectCallCount();
  error AccessSystemMock_IncorrectCaller();

  function accessController(uint256 entityId, bytes memory targetCallData) public view {
    // the goal of this controller is to ensure all data flows work properly for the access modifier
    // the following revert errors will only occur if the access modifier logic is incorrect
    // normally access logic will only revert when access permissions are breached

    // assume these values for verification in our test (they are the same values used in SmartObjectFramewrokTest.test_access())
    uint256 classId = uint256(bytes32("TEST_CLASS"));
    ResourceId targetSystemId = ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("TaggedSystemMock"))))
    );
    bytes4 targetFunctionId = SystemMock.accessControlled.selector;

    (uint256 targetParam1, ResourceId targetParam2, bytes4 targetParam3) = abi.decode(
      targetCallData,
      (uint256, ResourceId, bytes4)
    );

    // check entityId and targetCallData are passed correctly to the access logic
    if (entityId != classId || entityId != targetParam1) {
      revert AccessSystemMock_IncorrectEntityId(entityId, classId);
    }
    if (ResourceId.unwrap(targetParam2) != ResourceId.unwrap(targetSystemId) || targetParam3 != targetFunctionId) {
      revert AccessSystemMock_IncorrectCallData();
    }

    // assume our SystemMock.accessControlled has the enforceCallCount(1) modifier
    // check that the call count is not affected by this access logic call
    uint256 callCount = IWorldWithContext(_world()).getWorldCallCount();
    if (callCount != 1) {
      revert AccessSystemMock_IncorrectCallCount();
    }

    address targetAddress = Systems.getSystem(targetSystemId);
    // check this function is being called by the correct target system
    if (_msgSender() != targetAddress) {
      revert AccessSystemMock_IncorrectCaller();
    }
  }

  // check that non-view access functions throw an error
  function invalidAccessController(
    uint256 entityId,
    bytes memory targetCallData
  ) public returns (uint256, bytes memory) {
    // transient storage setting to ensure this is not a static call
    uint256 maxSlot = type(uint256).max;
    assembly {
      tstore(maxSlot, 0)
    }
    return (entityId, targetCallData);
  }
}
