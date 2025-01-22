// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Test } from "forge-std/Test.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IWorldWithContext } from "@eveworld/smart-object-framework-v2/src/IWorldWithContext.sol";

import { AccessConfig, HasRole } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/index.sol";

import { roleManagementSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/RoleManagementSystemLib.sol";
import { RoleManagementSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/systems/role-management-system/RoleManagementSystem.sol";
import { IRoleManagementSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/interfaces/IRoleManagementSystem.sol";

import { accessConfigSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/AccessConfigSystemLib.sol";
import { AccessConfigSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/systems/access-config-system/AccessConfigSystem.sol";

import { DeployableSystem } from "../src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { deployableSystem } from "../src/namespaces/evefrontier/codegen/systems/DeployableSystemLib.sol";

import { adminAccessSystem } from "../src/namespaces/evefrontier/codegen/systems/AdminAccessSystemLib.sol";
import { AdminAccessSystem } from "../src/namespaces/evefrontier/systems/access-systems/AdminAccessSystem.sol";

import { FuelSystem } from "../src/namespaces/evefrontier/systems/fuel/FuelSystem.sol";
import { fuelSystem } from "../src/namespaces/evefrontier/codegen/systems/FuelSystemLib.sol";

abstract contract EveTest is Test {
  address public worldAddress;
  IWorldWithContext world;

  string mnemonic = "test test test test test test test test test test test junk";

  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  address deployer = vm.addr(deployerPK);

  uint256 alicePK = vm.deriveKey(mnemonic, 2);
  address alice = vm.addr(alicePK);

  function setUp() public virtual {
    worldAddress = vm.envAddress("WORLD_ADDRESS");
    StoreSwitch.setStoreAddress(worldAddress);

    world = IWorldWithContext(worldAddress);

    _createRoles();
  }

  function _createRoles() internal {
    bytes32 adminRole = "admin";

    vm.startPrank(deployer);

    AccessConfig.register();
    HasRole.register();

    world.registerSystem(roleManagementSystem.toResourceId(), new RoleManagementSystem(), true);

    // Register all function selectors from IRoleManagementSystem interface
    string[5] memory signatures = [
      "createRole(bytes32,bytes32)",
      "transferRoleAdmin(bytes32,bytes32)",
      "grantRole(bytes32,address)",
      "revokeRole(bytes32,address)",
      "renounceRole(bytes32,address)"
    ];

    for (uint256 i = 0; i < signatures.length; i++) {
      world.registerFunctionSelector(roleManagementSystem.toResourceId(), signatures[i]);
    }

    world.registerSystem(accessConfigSystem.toResourceId(), new AccessConfigSystem(), true);
    string[2] memory accessConfigSignatures = [
      "configureAccess(bytes32,bytes4,bytes32,bytes4)",
      "setAccessEnforcement(bytes32,bytes4,bool)"
    ];

    for (uint256 i = 0; i < accessConfigSignatures.length; i++) {
      world.registerFunctionSelector(accessConfigSystem.toResourceId(), accessConfigSignatures[i]);
    }

    roleManagementSystem.createRole(adminRole, adminRole);

    // DeployableSystem

    bytes4[10] memory deployableSignatures = [
      DeployableSystem.createAndAnchorDeployable.selector,
      DeployableSystem.registerDeployable.selector,
      DeployableSystem.registerDeployableToken.selector,
      DeployableSystem.destroyDeployable.selector,
      DeployableSystem.bringOnline.selector,
      DeployableSystem.bringOffline.selector,
      DeployableSystem.anchor.selector,
      DeployableSystem.unanchor.selector,
      DeployableSystem.globalPause.selector,
      DeployableSystem.globalResume.selector
    ];

    for (uint256 i = 0; i < deployableSignatures.length; i++) {
      accessConfigSystem.configureAccess(
        deployableSystem.toResourceId(),
        deployableSignatures[i],
        adminAccessSystem.toResourceId(),
        AdminAccessSystem.onlyAdmin.selector
      );

      accessConfigSystem.setAccessEnforcement(deployableSystem.toResourceId(), deployableSignatures[i], true);
    }

    // FuelSystem

    // bytes4[8] memory fuelSignatures = [
    //   FuelSystem.configureFuelParameters.selector,
    //   FuelSystem.setFuelUnitVolume.selector,
    //   FuelSystem.setFuelConsumptionIntervalInSeconds.selector,
    //   FuelSystem.setFuelMaxCapacity.selector,
    //   FuelSystem.setFuelAmount.selector,
    //   FuelSystem.depositFuel.selector,
    //   FuelSystem.withdrawFuel.selector,
    //   FuelSystem.updateFuel.selector
    // ];

    // for (uint256 i = 0; i < fuelSignatures.length; i++) {
    //   accessConfigSystem.configureAccess(
    //     fuelSystem.toResourceId(),
    //     fuelSignatures[i],
    //     adminAccessSystem.toResourceId(),
    //     AdminAccessSystem.onlyAdmin.selector
    //   );

    //   accessConfigSystem.setAccessEnforcement(fuelSystem.toResourceId(), fuelSignatures[i], true);
    // }

    vm.stopPrank();
  }
}
