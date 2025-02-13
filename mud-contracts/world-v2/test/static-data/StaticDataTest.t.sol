// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { entitySystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/EntitySystemLib.sol";

import { StaticData } from "../../src/namespaces/evefrontier/codegen/tables/StaticData.sol";
import { StaticDataMetadata } from "../../src/namespaces/evefrontier/codegen/tables/StaticDataMetadata.sol";
import { StaticDataSystemLib, staticDataSystem } from "../../src/namespaces/evefrontier/codegen/systems/StaticDataSystemLib.sol";
import { EveTest } from "../EveTest.sol";

contract StaticDataTest is EveTest {
  uint256 testClassId = uint256(bytes32("TEST"));
  uint256 smartObjectId = 1234;

  function setUp() public virtual override {
    super.setUp();
    vm.startPrank(deployer);
    ResourceId[] memory systemIds = new ResourceId[](1);
    systemIds[0] = staticDataSystem.toResourceId();
    entitySystem.registerClass(testClassId, "admin", systemIds);
    vm.stopPrank();
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
    vm.startPrank(deployer);
    staticDataSystem.setBaseURI(baseURI);

    string memory baseuri = StaticDataMetadata.get();
    assertEq(baseURI, baseuri);
    vm.stopPrank();
  }

  function testSetCid(string memory cid) public {
    vm.startPrank(deployer);
    entitySystem.instantiate(testClassId, smartObjectId);
    staticDataSystem.setCid(smartObjectId, cid);

    string memory storedCid = StaticData.get(smartObjectId);
    assertEq(cid, storedCid);
    vm.stopPrank();
  }
}
