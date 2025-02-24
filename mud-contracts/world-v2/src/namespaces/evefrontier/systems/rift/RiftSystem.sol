// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { Rift } from "../../codegen/index.sol";
import { inventorySystem } from "../../codegen/systems/InventorySystemLib.sol";
import { crudeLiftSystem } from "../../codegen/systems/CrudeLiftSystemLib.sol";

uint256 constant CRUDE_MATTER = 1;

contract RiftSystem is SmartObjectFramework {
  error RiftAlreadyExists();
  error RiftAlreadyCollapsed();

  // A rift is created with only an amount onchain
  // Location is "shielded" by the game server
  function createRift(uint256 riftId, uint256 crudeAmount) public {
    if (Rift.getCreatedAt(riftId) != 0) revert RiftAlreadyExists();

    inventorySystem.setInventoryCapacity(riftId, crudeAmount);
    crudeLiftSystem.addCrude(riftId, crudeAmount);

    Rift.setCreatedAt(riftId, block.timestamp);
  }

  function destroyRift(uint256 riftId) public {
    if (Rift.getCollapsedAt(riftId) != 0) revert RiftAlreadyCollapsed();

    crudeLiftSystem.clearCrude(riftId);

    Rift.setCollapsedAt(riftId, block.timestamp);
  }
}
