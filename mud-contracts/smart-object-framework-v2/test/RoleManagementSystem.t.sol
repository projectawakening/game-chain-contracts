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
import { IRoleManagementSystem } from "../src/namespaces/evefrontier/interfaces/IRoleManagementSystem.sol";
import { Utils as RoleManagementSystemUtils } from "../src/namespaces/evefrontier/systems/role-management-system/Utils.sol";

import "../src/namespaces/evefrontier/codegen/index.sol";

contract RoleManagementSystemTest is MudTest {
  using RoleManagementSystemUtils for bytes14;

  IBaseWorld world;

  bytes14 constant NAMESPACE = DEPLOYMENT_NAMESPACE;
  ResourceId constant NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, NAMESPACE)));
  ResourceId ROLE_MANAGEMENT_SYSTEM_ID = RoleManagementSystemUtils.roleManagementSystemId();

  bytes32 adminRole = bytes32("ADMIN_ROLE");
  bytes32 testRole = bytes32("TEST_ROLE");

  string constant mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  address deployer = vm.addr(deployerPK);
  uint256 alicePK = vm.deriveKey(mnemonic, 1);
  address alice = vm.addr(alicePK);

  function setUp() public override {
    // DEPLOY AND REGISTER A MUD WORLD
    worldAddress = vm.envAddress("WORLD_ADDRESS");
    world = IBaseWorld(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);
  }

  function test_createRole() public {
    vm.startPrank(deployer);
    // revert, if role or admin is bytes32(0)
    vm.expectRevert(abi.encodeWithSelector(IRoleManagementSystem.RoleManagement_InvalidRole.selector));
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (bytes32(0), adminRole)));
    vm.expectRevert(abi.encodeWithSelector(IRoleManagementSystem.RoleManagement_InvalidRole.selector));
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (testRole, bytes32(0))));

    // create a role which is admin for itself
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (adminRole, adminRole)));

    // check created role values
    RoleData memory adminRoleData = Role.get(adminRole);
    assertEq(adminRoleData.exists, true);
    assertEq(adminRoleData.admin, adminRole);

    // check that the entry point caller has been assigned as a member of this role
    bool hasRole = HasRole.get(adminRole, deployer);
    assertEq(hasRole, true);

    // revert if role already exists
    // revert RoleManagement_RoleAlreadyCreated(role);
    vm.expectRevert(
      abi.encodeWithSelector(IRoleManagementSystem.RoleManagement_RoleAlreadyCreated.selector, adminRole)
    );
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (adminRole, adminRole)));

    // create a role which has another role as admin
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (testRole, adminRole)));

    vm.stopPrank();
  }

  function test_transferRoleAdmin() public {
    vm.startPrank(deployer);
    // create two roles which have themselves as admin
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (testRole, testRole)));
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (adminRole, adminRole)));

    bytes32 doesNotExist = bytes32("DOES_NOT_EXIST");

    // revert, if admin does not exist
    vm.expectRevert(
      abi.encodeWithSelector(IRoleManagementSystem.RoleManagement_RoleDoesNotExist.selector, doesNotExist)
    );
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.transferRoleAdmin, (testRole, doesNotExist))
    );

    // revert, if admin is already assigned to this role
    vm.expectRevert(
      abi.encodeWithSelector(IRoleManagementSystem.RoleManagement_AdminAlreadyAssigned.selector, testRole, testRole)
    );
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.transferRoleAdmin, (testRole, testRole))
    );

    //success, change admin role of testRole to adminRole
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.transferRoleAdmin, (testRole, adminRole))
    );

    // check that the new admin was set for role in table
    RoleData memory testRoleData = Role.get(testRole);
    assertEq(testRoleData.admin, adminRole);
    vm.stopPrank();

    // revert, if caller is not an admin role member
    vm.expectRevert(
      abi.encodeWithSelector(
        IRoleManagementSystem.RoleManagement_UnauthorizedAccount.selector,
        adminRole,
        address(this)
      )
    );
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.transferRoleAdmin, (testRole, adminRole))
    );
  }

  function test_grantRole() public {
    vm.startPrank(deployer);
    // create a role
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (adminRole, adminRole)));

    // if an account already has a role, remain the same
    bool beforeHasRole = HasRole.get(adminRole, deployer);
    assertEq(beforeHasRole, true);
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.grantRole, (adminRole, deployer)));
    bool afterHasRole = HasRole.get(adminRole, deployer);
    assertEq(afterHasRole, true);

    // if account does not have a role, grant it
    bool beforeNewHasRole = HasRole.get(adminRole, alice);
    assertEq(beforeNewHasRole, false);
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.grantRole, (adminRole, alice)));
    bool afterNewHasRole = HasRole.get(adminRole, alice);
    assertEq(afterNewHasRole, true);
    vm.stopPrank();

    // revert, if caller is not an admin role member
    vm.expectRevert(
      abi.encodeWithSelector(
        IRoleManagementSystem.RoleManagement_UnauthorizedAccount.selector,
        adminRole,
        address(this)
      )
    );
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.grantRole, (adminRole, alice)));
  }

  function test_revokeRole() public {
    vm.startPrank(deployer);
    // create a role
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (adminRole, adminRole)));
    // revert if trying to revoke self
    vm.expectRevert(abi.encodeWithSelector(IRoleManagementSystem.RoleManagement_MustRenounceSelf.selector));
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.revokeRole, (adminRole, deployer)));

    // if an account does not have a role, remain the same
    bool beforeHasRole = HasRole.get(adminRole, alice);
    assertEq(beforeHasRole, false);
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.revokeRole, (adminRole, alice)));
    bool afterHasRole = HasRole.get(adminRole, alice);
    assertEq(afterHasRole, false);

    // grant alice the role
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.grantRole, (adminRole, alice)));

    // if account has a role, revoke it
    bool beforeNewHasRole = HasRole.get(adminRole, alice);
    assertEq(beforeNewHasRole, true);
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.revokeRole, (adminRole, alice)));
    bool afterNewHasRole = HasRole.get(adminRole, alice);
    assertEq(afterNewHasRole, false);
    vm.stopPrank();

    // revert, if caller is not an admin role member
    vm.expectRevert(
      abi.encodeWithSelector(
        IRoleManagementSystem.RoleManagement_UnauthorizedAccount.selector,
        adminRole,
        address(this)
      )
    );
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.revokeRole, (adminRole, alice)));
  }

  function test_renounceRole() public {
    vm.startPrank(deployer);
    // create a role
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (adminRole, adminRole)));

    // revert if trying to renounce with wrong confirmation account
    vm.expectRevert(abi.encodeWithSelector(IRoleManagementSystem.RoleManagement_BadConfirmation.selector));
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.renounceRole, (adminRole, alice)));

    // if account has a role, revoke it
    bool beforeHasRole = HasRole.get(adminRole, deployer);
    assertEq(beforeHasRole, true);
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.renounceRole, (adminRole, deployer)));
    bool afterHasRole = HasRole.get(adminRole, deployer);
    assertEq(afterHasRole, false);

    // if an account does not have a role, remain the same
    bool beforeDoesNotHaveRole = HasRole.get(adminRole, deployer);
    assertEq(beforeDoesNotHaveRole, false);
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.renounceRole, (adminRole, deployer)));
    bool afterDoesNotHaveRole = HasRole.get(adminRole, deployer);
    assertEq(afterDoesNotHaveRole, false);
    vm.stopPrank();
  }
}
