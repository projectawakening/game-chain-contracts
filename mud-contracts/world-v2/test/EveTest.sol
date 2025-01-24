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
import { AccessSystem } from "../src/namespaces/evefrontier/systems/access-systems/AccessSystem.sol";
import { accessSystem } from "../src/namespaces/evefrontier/codegen/systems/AccessSystemLib.sol";
import { FuelSystem } from "../src/namespaces/evefrontier/systems/fuel/FuelSystem.sol";
import { fuelSystem } from "../src/namespaces/evefrontier/codegen/systems/FuelSystemLib.sol";

import { inventorySystem } from "../src/namespaces/evefrontier/codegen/systems/InventorySystemLib.sol";
import { InventorySystem } from "../src/namespaces/evefrontier/systems/inventory/InventorySystem.sol";
import { InventoryInteractSystem } from "../src/namespaces/evefrontier/systems/inventory/InventoryInteractSystem.sol";
import { inventoryInteractSystem } from "../src/namespaces/evefrontier/codegen/systems/InventoryInteractSystemLib.sol";
import { EntityRecordSystem } from "../src/namespaces/evefrontier/systems/entity-record/EntityRecordSystem.sol";
import { entityRecordSystem } from "../src/namespaces/evefrontier/codegen/systems/EntityRecordSystemLib.sol";
import { StaticDataSystem } from "../src/namespaces/evefrontier/systems/static-data/StaticDataSystem.sol";
import { staticDataSystem } from "../src/namespaces/evefrontier/codegen/systems/StaticDataSystemLib.sol";

abstract contract EveTest is Test {
  address public worldAddress;
  IWorldWithContext world;

  string mnemonic = "test test test test test test test test test test test junk";

  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  address deployer = vm.addr(deployerPK);

  uint256 alicePK = vm.deriveKey(mnemonic, 2);
  address alice = vm.addr(alicePK);

  uint256 bobPK = vm.deriveKey(mnemonic, 3);
  address bob = vm.addr(bobPK);

  function setUp() public virtual {
    worldAddress = vm.envAddress("WORLD_ADDRESS");
    StoreSwitch.setStoreAddress(worldAddress);

    world = IWorldWithContext(worldAddress);

    _setupSmartObjectFramework();
  }

  function _setupSmartObjectFramework() internal {
    bytes32 adminRole = "admin";

    vm.startPrank(deployer);

    // SmartObjectFrameworkV2 Setup
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
    // End SmartObjectFrameworkV2 Setup

    // Role Creation
    roleManagementSystem.createRole(adminRole, adminRole);
    // TODO: Grant admin role to address list
    // End Role Creation

    // DeployableSystem

    bytes4[8] memory deployableSignatures = [
      DeployableSystem.createAndAnchorDeployable.selector,
      DeployableSystem.registerDeployable.selector,
      DeployableSystem.registerDeployableToken.selector,
      DeployableSystem.destroyDeployable.selector,
      DeployableSystem.anchor.selector,
      DeployableSystem.unanchor.selector,
      DeployableSystem.globalPause.selector,
      DeployableSystem.globalResume.selector
    ];

    for (uint256 i = 0; i < deployableSignatures.length; i++) {
      accessConfigSystem.configureAccess(
        deployableSystem.toResourceId(),
        deployableSignatures[i],
        accessSystem.toResourceId(),
        AccessSystem.onlyAdmin.selector
      );

      accessConfigSystem.setAccessEnforcement(deployableSystem.toResourceId(), deployableSignatures[i], true);
    }

    accessConfigSystem.configureAccess(
      deployableSystem.toResourceId(),
      DeployableSystem.bringOnline.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdminOrDeployableOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      deployableSystem.toResourceId(),
      DeployableSystem.bringOnline.selector,
      true
    );
    accessConfigSystem.configureAccess(
      deployableSystem.toResourceId(),
      DeployableSystem.bringOffline.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdminOrDeployableOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      deployableSystem.toResourceId(),
      DeployableSystem.bringOffline.selector,
      true
    );

    // EntityRecordSystem

    accessConfigSystem.configureAccess(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.createEntityRecordMetadata.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdminOrOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.createEntityRecordMetadata.selector,
      true
    );

    accessConfigSystem.configureAccess(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.setName.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdminOrOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.setName.selector,
      true
    );

    accessConfigSystem.configureAccess(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.setDappURL.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdminOrOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.setDappURL.selector,
      true
    );

    accessConfigSystem.configureAccess(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.setDescription.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdminOrOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.setDescription.selector,
      true
    );

    // StaticDataSystem
    accessConfigSystem.configureAccess(
      staticDataSystem.toResourceId(),
      StaticDataSystem.setCid.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(staticDataSystem.toResourceId(), StaticDataSystem.setCid.selector, true);

    accessConfigSystem.configureAccess(
      staticDataSystem.toResourceId(),
      StaticDataSystem.setBaseURI.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(
      staticDataSystem.toResourceId(),
      StaticDataSystem.setBaseURI.selector,
      true
    );

    // InventorySystem

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
