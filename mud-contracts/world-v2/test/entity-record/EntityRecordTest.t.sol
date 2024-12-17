// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";

import { IWorld } from "../../src/codegen/world/IWorld.sol";
import { EntityRecord } from "../../src/namespaces/evefrontier/codegen/index.sol";
import { EntityRecordSystemLib, entityRecordSystem } from "../../src/namespaces/evefrontier/codegen/systems/EntityRecordSystemLib.sol";
import { EntityRecord, EntityRecordData } from "../../src/namespaces/evefrontier/codegen/tables/EntityRecord.sol";
import { EntityRecordMetadata, EntityRecordMetadataData } from "../../src/namespaces/evefrontier/codegen/tables/EntityRecordMetadata.sol";
import { EntityRecordData as EntityRecordInput, EntityMetadata } from "../../src/namespaces/evefrontier/systems/entity-record/types.sol";

contract EntityRecordTest is MudTest {
  IBaseWorld world;

  function setUp() public virtual override {
    super.setUp();
    world = IBaseWorld(worldAddress);
  }

  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  function testEntityRecord(uint256 smartObjectId, uint256 itemId, uint256 typeId, uint256 volume) public {
    vm.assume(smartObjectId != 0);

    EntityRecordInput memory entityRecordInput = EntityRecordInput({ typeId: typeId, itemId: itemId, volume: volume });

    EntityRecordSystemLib.createEntityRecord(entityRecordSystem, smartObjectId, entityRecordInput);
    EntityRecordData memory entityRecord = EntityRecord.get(smartObjectId);

    assertEq(itemId, entityRecord.itemId);
    assertEq(typeId, entityRecord.typeId);
    assertEq(volume, entityRecord.volume);
  }

  function testEntityRecordMetadata(
    uint256 smartObjectId,
    string memory name,
    string memory dappURL,
    string memory description
  ) public {
    vm.assume(smartObjectId != 0);
    EntityMetadata memory entityMetadata = EntityMetadata({ name: name, dappURL: dappURL, description: description });

    EntityRecordSystemLib.createEntityRecordMetadata(entityRecordSystem, smartObjectId, entityMetadata);

    EntityRecordMetadataData memory entityRecordMetaData = EntityRecordMetadata.get(smartObjectId);

    assertEq(name, entityRecordMetaData.name);
    assertEq(dappURL, entityRecordMetaData.dappURL);
    assertEq(description, entityRecordMetaData.description);
  }

  function testSetName(uint256 smartObjectId, string memory name) public {
    vm.assume(smartObjectId != 0);
    EntityRecordSystemLib.setName(entityRecordSystem, smartObjectId, name);

    EntityRecordMetadataData memory entityRecordMetaData = EntityRecordMetadata.get(smartObjectId);

    assertEq(name, entityRecordMetaData.name);
  }
}
