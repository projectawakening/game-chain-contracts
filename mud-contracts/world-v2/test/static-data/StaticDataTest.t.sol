// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";

import { StaticData } from "../../src/namespaces/evefrontier/codegen/tables/StaticData.sol";
import { StaticDataMetadata } from "../../src/namespaces/evefrontier/codegen/tables/StaticDataMetadata.sol";
import { StaticDataSystemLib, staticDataSystem } from "../../src/namespaces/evefrontier/codegen/systems/StaticDataSystemLib.sol";

contract StaticDataTest is MudTest {
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

  function testSetBaseURI(string memory baseURI) public {
    staticDataSystem.setBaseURI(baseURI);

    string memory baseuri = StaticDataMetadata.get();
    assertEq(baseURI, baseuri);
  }

  function testSetCid(uint256 smartObjectId, string memory cid) public {
    vm.assume(smartObjectId != 0);
    staticDataSystem.setCid(smartObjectId, cid);

    string memory storedCid = StaticData.get(smartObjectId);
    assertEq(cid, storedCid);
  }
}
