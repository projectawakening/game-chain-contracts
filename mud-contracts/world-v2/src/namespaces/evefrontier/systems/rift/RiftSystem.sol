// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { EveSystem } from "../EveSystem.sol";
import { InventorySystem } from "../inventory/InventorySystem.sol";
import { EphemeralInventorySystem } from "../inventory/EphemeralInventorySystem.sol";
import { DeployableSystem } from "../deployable/DeployableSystem.sol";
import { DeployableUtils } from "../deployable/DeployableUtils.sol";
import { InventoryUtils } from "../inventory/InventoryUtils.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { InventoryItem, TransferItem } from "../inventory/types.sol";
import { State, SmartObjectData } from "../deployable/types.sol";
import { WorldPosition } from "../location/types.sol";
import { CRUDE_RIFT } from "../constants.sol";
import { EntityRecordData, Rift, RiftData, LocationData, Lens, DeployableToken } from "../../codegen/index.sol";

uint256 constant CRUDE_MATTER = 1;

contract RiftSystem is EveSystem {
  using WorldResourceIdLib for ResourceId;

  ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
  ResourceId inventorySystemId = InventoryUtils.inventorySystemId();
  ResourceId ephemeralInventorySystemId = InventoryUtils.ephemeralInventorySystemId();

  error RiftAlreadyExists();

  modifier onlyServer() {
    // TODO: Implement
    _;
  }

  // A rift is created with only an amount onchain
  // Location is "shielded" by the game server
  function createRift(uint256 riftId, uint256 crudeAmount) public onlyServer {
    if (Rift.getCreatedAt(riftId) != 0) revert RiftAlreadyExists();

    Rift.setCrudeAmount(riftId, crudeAmount);
    Rift.setCreatedAt(riftId, block.timestamp);

    // Mint Crude ERC20 or equivalent
  }
}
