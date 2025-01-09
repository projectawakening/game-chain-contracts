// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { World } from "@latticexyz/world/src/World.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";

import { Location } from "../../src/namespaces/evefrontier/codegen/tables/Location.sol";
import { LocationData } from "../../src/namespaces/evefrontier/codegen/tables/Location.sol";
import { LocationSystemLib, locationSystem } from "../../src/namespaces/evefrontier/codegen/systems/LocationSystemLib.sol";

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

  function testSaveLocation(uint256 smartObjectId, uint256 solarSystemId, uint256 x, uint256 y, uint256 z) public {
    vm.assume(smartObjectId != 0);

    locationSystem.saveLocation(smartObjectId, LocationData({ solarSystemId: solarSystemId, x: x, y: y, z: z }));

    LocationData memory location = Location.get(smartObjectId);

    assertEq(solarSystemId, location.solarSystemId);
    assertEq(x, location.x);
    assertEq(y, location.y);
    assertEq(z, location.z);
  }

  function testGetLocation(uint256 smartObjectId, uint256 solarSystemId, uint256 x, uint256 y, uint256 z) public {
    vm.assume(smartObjectId != 0);

    locationSystem.saveLocation(smartObjectId, LocationData({ solarSystemId: solarSystemId, x: x, y: y, z: z }));

    LocationData memory location = Location.get(smartObjectId);

    assertEq(solarSystemId, location.solarSystemId);
    assertEq(x, location.x);
    assertEq(y, location.y);
    assertEq(z, location.z);
  }

  function testSetSolarSystemId(uint256 smartObjectId, uint256 solarSystemId) public {
    vm.assume(smartObjectId != 0);

    locationSystem.setSolarSystemId(smartObjectId, solarSystemId);

    LocationData memory location = Location.get(smartObjectId);
    assertEq(solarSystemId, location.solarSystemId);
  }

  function testSetX(uint256 smartObjectId, uint256 x) public {
    vm.assume(smartObjectId != 0);

    locationSystem.setX(smartObjectId, x);

    LocationData memory location = Location.get(smartObjectId);
    assertEq(x, location.x);
  }

  function testSetY(uint256 smartObjectId, uint256 y) public {
    vm.assume(smartObjectId != 0);

    locationSystem.setY(smartObjectId, y);

    LocationData memory location = Location.get(smartObjectId);
    assertEq(y, location.y);
  }

  function testSetZ(uint256 smartObjectId, uint256 z) public {
    vm.assume(smartObjectId != 0);

    locationSystem.setZ(smartObjectId, z);

    LocationData memory location = Location.get(smartObjectId);
    assertEq(z, location.z);
  }
}
