// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";

import { World } from "@latticexyz/world/src/World.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdInstance, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_NAMESPACE, RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";

import { DEPLOYMENT_NAMESPACE } from "../src/namespaces/evefrontier/constants.sol";
import { IAccessConfigSystem } from "../src/namespaces/evefrontier/interfaces/IAccessConfigSystem.sol";
import { Utils as AccessConfigSystemUtils } from "../src/namespaces/evefrontier/systems/access-config-system/Utils.sol";

import "../src/namespaces/evefrontier/codegen/index.sol";

import { SystemMock } from "./mocks/SystemMock.sol";
import { AccessSystemMock } from "./mocks/AccessSystemMock.sol";

contract AccessConfigSystemTest is MudTest {
  using AccessConfigSystemUtils for bytes14;

  IBaseWorld world;
  SystemMock targetSystemMock;
  AccessSystemMock accessSystemMock;

  bytes14 constant NAMESPACE = DEPLOYMENT_NAMESPACE;
  ResourceId constant NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, NAMESPACE)));
  ResourceId ACCESS_CONFIG_SYSTEM_ID = AccessConfigSystemUtils.accessConfigSystemId();
  ResourceId TARGET_SYSTEM_ID =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("TargetSystemMock")))));
  ResourceId constant ACCESS_NAMESPACE_ID =
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, bytes14("AccessNamespac"))));
  ResourceId ACCESS_SYSTEM_ID =
    ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("AccessNamespac"), bytes16("AccessSystemMock"))))
    );
  string constant mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  uint256 alicePK = vm.deriveKey(mnemonic, 1);
  address deployer = vm.addr(deployerPK);
  address alice = vm.addr(alicePK);

  function setUp() public override {
    // DEPLOY AND REGISTER A MUD WORLD
    worldAddress = vm.envAddress("WORLD_ADDRESS");
    world = IBaseWorld(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);
    vm.startPrank(deployer);
    // DEPLOY THE MOCK SYSTEM AS OUR TARGET SYSTEM
    targetSystemMock = new SystemMock();
    /// DEPLOY THE ACCESS MOCK SYSTEM AS OUR ACCESS SYSTEM
    accessSystemMock = new AccessSystemMock();
    vm.stopPrank();
  }

  function test_configureAccess() public {
    vm.startPrank(deployer);
    // revert, if target system is not registered
    vm.expectRevert(
      abi.encodeWithSelector(IAccessConfigSystem.AccessConfig_InvalidTargetSystem.selector, TARGET_SYSTEM_ID)
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.configureAccess,
        (
          TARGET_SYSTEM_ID,
          SystemMock.accessControlled.selector,
          ACCESS_SYSTEM_ID,
          AccessSystemMock.accessController.selector
        )
      )
    );

    // register target system
    world.registerSystem(TARGET_SYSTEM_ID, System(targetSystemMock), true);

    // revert, if access system is not registered
    vm.expectRevert(
      abi.encodeWithSelector(IAccessConfigSystem.AccessConfig_InvalidAccessSystem.selector, ACCESS_SYSTEM_ID)
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.configureAccess,
        (
          TARGET_SYSTEM_ID,
          SystemMock.accessControlled.selector,
          ACCESS_SYSTEM_ID,
          AccessSystemMock.accessController.selector
        )
      )
    );

    // register access namespace and system
    world.registerNamespace(ACCESS_NAMESPACE_ID);
    world.registerSystem(ACCESS_SYSTEM_ID, System(accessSystemMock), true);

    // success
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.configureAccess,
        (
          TARGET_SYSTEM_ID,
          SystemMock.accessControlled.selector,
          ACCESS_SYSTEM_ID,
          AccessSystemMock.accessController.selector
        )
      )
    );
    bytes32 target = keccak256(abi.encodePacked(TARGET_SYSTEM_ID, SystemMock.accessControlled.selector));
    // check that the access config is set correctly in the AccessConfig table
    AccessConfigData memory accessConfig = AccessConfig.get(target);
    assertEq(accessConfig.configured, true);
    assertEq(accessConfig.targetSystemId.unwrap(), TARGET_SYSTEM_ID.unwrap());
    assertEq(accessConfig.targetFunctionId, SystemMock.accessControlled.selector);
    assertEq(accessConfig.accessSystemId.unwrap(), ACCESS_SYSTEM_ID.unwrap());
    assertEq(accessConfig.accessFunctionId, AccessSystemMock.accessController.selector);
    assertEq(accessConfig.enforcement, false);
    vm.stopPrank();

    // revert, if the direct caller _msgSender() is not the namespace owner of the target system
    vm.expectRevert(
      abi.encodeWithSelector(IAccessConfigSystem.AccessConfig_AccessDenied.selector, TARGET_SYSTEM_ID, address(this))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.configureAccess,
        (
          TARGET_SYSTEM_ID,
          SystemMock.accessControlled.selector,
          ACCESS_SYSTEM_ID,
          AccessSystemMock.accessController.selector
        )
      )
    );
  }

  // setAccessEnforcement(ResourceId targetSystemId, bytes4 targetFunctionId, bool enforced)
  function test_setAccessEnforcement() public {
    vm.startPrank(deployer);
    // register target system
    world.registerSystem(TARGET_SYSTEM_ID, System(targetSystemMock), true);
    // register access namespace and system
    world.registerNamespace(ACCESS_NAMESPACE_ID);
    world.registerSystem(ACCESS_SYSTEM_ID, System(accessSystemMock), true);

    // revert, if target is not configured
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessConfigSystem.AccessConfig_TargetNotConfigured.selector,
        TARGET_SYSTEM_ID,
        SystemMock.accessControlled.selector
      )
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.setAccessEnforcement,
        (TARGET_SYSTEM_ID, SystemMock.accessControlled.selector, true)
      )
    );

    // configure access
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.configureAccess,
        (
          TARGET_SYSTEM_ID,
          SystemMock.accessControlled.selector,
          ACCESS_SYSTEM_ID,
          AccessSystemMock.accessController.selector
        )
      )
    );

    // check that the access enforcement is not on
    bytes32 target = keccak256(abi.encodePacked(TARGET_SYSTEM_ID, SystemMock.accessControlled.selector));
    bool enforcementBefore = AccessConfig.getEnforcement(target);
    assertEq(enforcementBefore, false);
    // success
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.setAccessEnforcement,
        (TARGET_SYSTEM_ID, SystemMock.accessControlled.selector, true)
      )
    );
    // check that the access enforcement is on
    bool enforcementAfter = AccessConfig.getEnforcement(target);
    assertEq(enforcementAfter, true);
    vm.stopPrank();

    // revert, if the direct caller _msgSender() is not the namespace owner of the target system
    vm.expectRevert(
      abi.encodeWithSelector(IAccessConfigSystem.AccessConfig_AccessDenied.selector, TARGET_SYSTEM_ID, address(this))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(
        IAccessConfigSystem.setAccessEnforcement,
        (TARGET_SYSTEM_ID, SystemMock.accessControlled.selector, true)
      )
    );
  }
}
