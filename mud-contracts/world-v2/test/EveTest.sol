// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Test } from "forge-std/Test.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IWorldWithContext } from "@eveworld/smart-object-framework-v2/src/IWorldWithContext.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { AccessConfig, HasRole, Entity, EntityTagMap, Role } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/index.sol";

import { roleManagementSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/RoleManagementSystemLib.sol";
import { RoleManagementSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/systems/role-management-system/RoleManagementSystem.sol";
import { IRoleManagementSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/interfaces/IRoleManagementSystem.sol";

import { accessConfigSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/AccessConfigSystemLib.sol";
import { AccessConfigSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/systems/access-config-system/AccessConfigSystem.sol";

import { entitySystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/EntitySystemLib.sol";
import { EntitySystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/systems/entity-system/EntitySystem.sol";

import { tagSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/systems/TagSystemLib.sol";
import { TagSystem } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/systems/tag-system/TagSystem.sol";

import { DeployableSystem } from "../src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";
import { deployableSystem } from "../src/namespaces/evefrontier/codegen/systems/DeployableSystemLib.sol";
import { AccessSystem } from "../src/namespaces/evefrontier/systems/access-systems/AccessSystem.sol";
import { accessSystem } from "../src/namespaces/evefrontier/codegen/systems/AccessSystemLib.sol";
import { FuelSystem } from "../src/namespaces/evefrontier/systems/fuel/FuelSystem.sol";
import { fuelSystem } from "../src/namespaces/evefrontier/codegen/systems/FuelSystemLib.sol";

import { inventorySystem } from "../src/namespaces/evefrontier/codegen/systems/InventorySystemLib.sol";
import { InventorySystem } from "../src/namespaces/evefrontier/systems/inventory/InventorySystem.sol";
import { ephemeralInventorySystem } from "../src/namespaces/evefrontier/codegen/systems/EphemeralInventorySystemLib.sol";
import { EphemeralInventorySystem } from "../src/namespaces/evefrontier/systems/inventory/EphemeralInventorySystem.sol";
import { InventoryInteractSystem } from "../src/namespaces/evefrontier/systems/inventory/InventoryInteractSystem.sol";
import { inventoryInteractSystem } from "../src/namespaces/evefrontier/codegen/systems/InventoryInteractSystemLib.sol";
import { EntityRecordSystem } from "../src/namespaces/evefrontier/systems/entity-record/EntityRecordSystem.sol";
import { entityRecordSystem } from "../src/namespaces/evefrontier/codegen/systems/EntityRecordSystemLib.sol";
import { StaticDataSystem } from "../src/namespaces/evefrontier/systems/static-data/StaticDataSystem.sol";
import { staticDataSystem } from "../src/namespaces/evefrontier/codegen/systems/StaticDataSystemLib.sol";
import { LocationSystem } from "../src/namespaces/evefrontier/systems/location/LocationSystem.sol";
import { locationSystem } from "../src/namespaces/evefrontier/codegen/systems/LocationSystemLib.sol";
import { SmartCharacterSystem } from "../src/namespaces/evefrontier/systems/smart-character/SmartCharacterSystem.sol";
import { smartCharacterSystem } from "../src/namespaces/evefrontier/codegen/systems/SmartCharacterSystemLib.sol";

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
    Entity.register();
    EntityTagMap.register();
    Role.register();

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

    world.registerSystem(entitySystem.toResourceId(), new EntitySystem(), true);
    string[2] memory entitySignatures = ["instantiate(uint256,uint256)", "registerClass(uint256,bytes32,ResourceId[])"];
    for (uint256 i = 0; i < entitySignatures.length; i++) {
      world.registerFunctionSelector(entitySystem.toResourceId(), entitySignatures[i]);
    }

    world.registerSystem(tagSystem.toResourceId(), new TagSystem(), true);
    string[1] memory tagSignatures = ["setTags(uint256,(bytes32,bytes)[])"];
    for (uint256 i = 0; i < tagSignatures.length; i++) {
      world.registerFunctionSelector(tagSystem.toResourceId(), tagSignatures[i]);
    }

    // End SmartObjectFrameworkV2 Setup

    // Role Creation
    roleManagementSystem.createRole(adminRole, adminRole);
    // TODO: Grant admin role to address list
    roleManagementSystem.grantRole(adminRole, deployer);
    // End Role Creation

    // Class Creation
    uint256 smartStorageUnitClassId = uint256(bytes32("SSU"));
    ResourceId[] memory systemIds = new ResourceId[](5);
    systemIds[0] = inventorySystem.toResourceId();
    systemIds[1] = deployableSystem.toResourceId();
    systemIds[2] = ephemeralInventorySystem.toResourceId();
    systemIds[3] = inventoryInteractSystem.toResourceId();
    systemIds[4] = entityRecordSystem.toResourceId();
    entitySystem.registerClass(smartStorageUnitClassId, adminRole, systemIds);

    uint256 smartCharacterClassId = uint256(bytes32("SMART_CHARACTER"));
    systemIds = new ResourceId[](1);
    systemIds[0] = entityRecordSystem.toResourceId();

    entitySystem.registerClass(smartCharacterClassId, adminRole, systemIds);
    // End Class Creation

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
      EntityRecordSystem.createEntityRecord.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.createEntityRecord.selector,
      true
    );

    accessConfigSystem.configureAccess(
      entityRecordSystem.toResourceId(),
      EntityRecordSystem.createEntityRecordMetadata.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdminOrDeployableOwner.selector
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
      AccessSystem.onlyAdminOrDeployableOwner.selector
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
      AccessSystem.onlyAdminOrDeployableOwner.selector
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
      AccessSystem.onlyAdminOrDeployableOwner.selector
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

    // EphemeralInventorySystem

    accessConfigSystem.configureAccess(
      ephemeralInventorySystem.toResourceId(),
      EphemeralInventorySystem.setEphemeralInventoryCapacity.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(
      ephemeralInventorySystem.toResourceId(),
      EphemeralInventorySystem.setEphemeralInventoryCapacity.selector,
      true
    );

    accessConfigSystem.configureAccess(
      ephemeralInventorySystem.toResourceId(),
      EphemeralInventorySystem.depositToEphemeralInventory.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyDeployableOwnerOrInventoryInteractSystem.selector
    );
    accessConfigSystem.setAccessEnforcement(
      ephemeralInventorySystem.toResourceId(),
      EphemeralInventorySystem.depositToEphemeralInventory.selector,
      true
    );

    accessConfigSystem.configureAccess(
      ephemeralInventorySystem.toResourceId(),
      EphemeralInventorySystem.withdrawFromEphemeralInventory.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyDeployableOwnerOrInventoryInteractSystem.selector
    );
    accessConfigSystem.setAccessEnforcement(
      ephemeralInventorySystem.toResourceId(),
      EphemeralInventorySystem.withdrawFromEphemeralInventory.selector,
      true
    );

    // InventoryInteractSystem

    accessConfigSystem.configureAccess(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.ephemeralToInventoryTransfer.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyOwnerOrCanDepositToInventory.selector
    );
    accessConfigSystem.setAccessEnforcement(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.ephemeralToInventoryTransfer.selector,
      true
    );

    accessConfigSystem.configureAccess(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.inventoryToEphemeralTransfer.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyOwnerOrCanWithdrawFromInventory.selector
    );
    accessConfigSystem.setAccessEnforcement(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.inventoryToEphemeralTransfer.selector,
      true
    );

    accessConfigSystem.configureAccess(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.setEphemeralToInventoryTransferAccess.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyDeployableOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.setEphemeralToInventoryTransferAccess.selector,
      true
    );

    accessConfigSystem.configureAccess(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.setInventoryToEphemeralTransferAccess.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyDeployableOwner.selector
    );
    accessConfigSystem.setAccessEnforcement(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.setInventoryToEphemeralTransferAccess.selector,
      true
    );

    accessConfigSystem.configureAccess(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.setInventoryAdminAccess.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyInventoryAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(
      inventoryInteractSystem.toResourceId(),
      InventoryInteractSystem.setInventoryAdminAccess.selector,
      true
    );

    // LocationSystem

    accessConfigSystem.configureAccess(
      locationSystem.toResourceId(),
      LocationSystem.saveLocation.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(locationSystem.toResourceId(), LocationSystem.saveLocation.selector, true);

    accessConfigSystem.configureAccess(
      locationSystem.toResourceId(),
      LocationSystem.setSolarSystemId.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(
      locationSystem.toResourceId(),
      LocationSystem.setSolarSystemId.selector,
      true
    );

    accessConfigSystem.configureAccess(
      locationSystem.toResourceId(),
      LocationSystem.setX.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(locationSystem.toResourceId(), LocationSystem.setX.selector, true);

    accessConfigSystem.configureAccess(
      locationSystem.toResourceId(),
      LocationSystem.setY.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(locationSystem.toResourceId(), LocationSystem.setY.selector, true);

    accessConfigSystem.configureAccess(
      locationSystem.toResourceId(),
      LocationSystem.setZ.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(locationSystem.toResourceId(), LocationSystem.setZ.selector, true);

    // SmartCharacterSystem

    accessConfigSystem.configureAccess(
      smartCharacterSystem.toResourceId(),
      SmartCharacterSystem.registerCharacterToken.selector,
      accessSystem.toResourceId(),
      AccessSystem.onlyAdmin.selector
    );
    accessConfigSystem.setAccessEnforcement(
      smartCharacterSystem.toResourceId(),
      SmartCharacterSystem.registerCharacterToken.selector,
      true
    );

    // TODO: come back to permission for createCharacter and updateTribeId

    // DeployableSystem

    bytes4[8] memory adminOnlySignatures = [
      DeployableSystem.createAndAnchorDeployable.selector,
      DeployableSystem.registerDeployableToken.selector,
      DeployableSystem.registerDeployable.selector,
      DeployableSystem.destroyDeployable.selector,
      DeployableSystem.anchor.selector,
      DeployableSystem.unanchor.selector,
      DeployableSystem.globalPause.selector,
      DeployableSystem.globalResume.selector
    ];
    for (uint256 i = 0; i < adminOnlySignatures.length; i++) {
      accessConfigSystem.configureAccess(
        deployableSystem.toResourceId(),
        adminOnlySignatures[i],
        accessSystem.toResourceId(),
        AccessSystem.onlyAdmin.selector
      );

      accessConfigSystem.setAccessEnforcement(deployableSystem.toResourceId(), adminOnlySignatures[i], true);
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

    // FuelSystem

    bytes4[7] memory fuelSignatures = [
      FuelSystem.configureFuelParameters.selector,
      FuelSystem.setFuelUnitVolume.selector,
      FuelSystem.setFuelConsumptionIntervalInSeconds.selector,
      FuelSystem.setFuelMaxCapacity.selector,
      FuelSystem.setFuelAmount.selector,
      FuelSystem.depositFuel.selector,
      FuelSystem.withdrawFuel.selector,
    ];

    for (uint256 i = 0; i < fuelSignatures.length; i++) {
      accessConfigSystem.configureAccess(
        fuelSystem.toResourceId(),
        fuelSignatures[i],
        adminAccessSystem.toResourceId(),
        AdminAccessSystem.onlyAdmin.selector
      );

      accessConfigSystem.setAccessEnforcement(fuelSystem.toResourceId(), fuelSignatures[i], true);
    }

    vm.stopPrank();
  }
}
