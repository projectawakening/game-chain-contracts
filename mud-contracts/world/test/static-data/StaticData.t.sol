// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";

import { World } from "@latticexyz/world/src/World.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { IModule } from "@latticexyz/world/src/IModule.sol";

import { SMART_OBJECT_DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";
import { SmartObjectFrameworkModule } from "@eveworld/smart-object-framework/src/SmartObjectFrameworkModule.sol";
import { EntitySystem } from "@eveworld/smart-object-framework/src/systems/core/EntitySystem.sol";
import { HookSystem } from "@eveworld/smart-object-framework/src/systems/core/HookSystem.sol";
import { ModuleSystem } from "@eveworld/smart-object-framework/src/systems/core/ModuleSystem.sol";

import { STATIC_DATA_DEPLOYMENT_NAMESPACE as DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";

import { Utils } from "../../src/modules/static-data/Utils.sol";
import { StaticDataModule } from "../../src/modules/static-data/StaticDataModule.sol";
import { StaticDataLib } from "../../src/modules/static-data/StaticDataLib.sol";
import { createCoreModule } from "../CreateCoreModule.sol";
import { StaticDataGlobalTable, StaticDataTable } from "../../src/codegen/index.sol";
import { StaticDataGlobalTableData } from "../../src/codegen/tables/StaticDataGlobalTable.sol";

// TODO: more thorough testing

contract StaticDataTest is Test {
  using Utils for bytes14;
  using StaticDataLib for StaticDataLib.World;
  using WorldResourceIdInstance for ResourceId;

  IBaseWorld world;
  StaticDataLib.World staticData;

  function setUp() public {
    world = IBaseWorld(address(new World()));
    world.initialize(createCoreModule());
    // required for `NamespaceOwner` and `WorldResourceIdLib` to infer current World Address properly
    StoreSwitch.setStoreAddress(address(world));

    // installing SOF module (dependancy)
    world.installModule(
      new SmartObjectFrameworkModule(),
      abi.encode(SMART_OBJECT_DEPLOYMENT_NAMESPACE, new EntitySystem(), new HookSystem(), new ModuleSystem())
    );

    _installModule(new StaticDataModule(), DEPLOYMENT_NAMESPACE);

    staticData = StaticDataLib.World(world, DEPLOYMENT_NAMESPACE);
  }

  // helper function to guard against multiple module registrations on the same namespace
  // TODO: Those kind of functions are used across all unit tests, ideally it should be inherited from a base Test contract
  function _installModule(IModule module, bytes14 namespace) internal {
    if (NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(namespace)) == address(this))
      world.transferOwnership(WorldResourceIdLib.encodeNamespace(namespace), address(module));
    world.installModule(module, abi.encode(namespace));
  }

  function testSetup() public {
    address staticDataSystem = Systems.getSystem(DEPLOYMENT_NAMESPACE.staticDataSystemId());
    ResourceId staticDataSystemId = SystemRegistry.get(staticDataSystem);
    assertEq(staticDataSystemId.getNamespace(), DEPLOYMENT_NAMESPACE);
  }

  function testSetBaseURI(ResourceId systemId, string memory newURI) public {
    vm.assume(ResourceId.unwrap(systemId) != bytes32(0));
    vm.assume(bytes(newURI).length != 0);

    staticData.setBaseURI(systemId, newURI);
    assertEq(StaticDataGlobalTable.getBaseURI(DEPLOYMENT_NAMESPACE.staticDataGlobalTableId(), systemId), newURI);
  }

  function testSetName(ResourceId systemId, string memory newName) public {
    vm.assume(ResourceId.unwrap(systemId) != bytes32(0));
    vm.assume(bytes(newName).length != 0);

    staticData.setName(systemId, newName);
    assertEq(StaticDataGlobalTable.getName(DEPLOYMENT_NAMESPACE.staticDataGlobalTableId(), systemId), newName);
  }

  function testSetSymbol(ResourceId systemId, string memory newSymbol) public {
    vm.assume(ResourceId.unwrap(systemId) != bytes32(0));
    vm.assume(bytes(newSymbol).length != 0);

    staticData.setSymbol(systemId, newSymbol);
    assertEq(StaticDataGlobalTable.getSymbol(DEPLOYMENT_NAMESPACE.staticDataGlobalTableId(), systemId), newSymbol);
  }

  function testSetMetadata(
    ResourceId systemId,
    string memory newURI,
    string memory newName,
    string memory newSymbol
  ) public {
    vm.assume(ResourceId.unwrap(systemId) != bytes32(0));
    vm.assume(bytes(newURI).length != 0);
    vm.assume(bytes(newName).length != 0);
    vm.assume(bytes(newSymbol).length != 0);

    staticData.setMetadata(systemId, StaticDataGlobalTableData({ name: newName, symbol: newSymbol, baseURI: newURI }));

    assertEq(StaticDataGlobalTable.getBaseURI(DEPLOYMENT_NAMESPACE.staticDataGlobalTableId(), systemId), newURI);
    assertEq(StaticDataGlobalTable.getName(DEPLOYMENT_NAMESPACE.staticDataGlobalTableId(), systemId), newName);
    assertEq(StaticDataGlobalTable.getSymbol(DEPLOYMENT_NAMESPACE.staticDataGlobalTableId(), systemId), newSymbol);
  }

  function testSetCID(uint256 entityId, string memory newCid) public {
    vm.assume(entityId != 0);
    vm.assume(bytes(newCid).length != 0);

    staticData.setCid(entityId, newCid);
    assertEq(StaticDataTable.getCid(DEPLOYMENT_NAMESPACE.staticDataTableId(), entityId), newCid);
  }
}
