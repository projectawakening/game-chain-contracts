// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import { Script } from "forge-std/Script.sol";

import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceAccess } from "@latticexyz/world/src/codegen/tables/ResourceAccess.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { FRONTIER_WORLD_DEPLOYMENT_NAMESPACE as WORLD_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";

import { Utils as AccessConfigUtils } from "../src/namespaces/evefrontier/systems/access-config-system/Utils.sol";
import { Utils as EntitySystemUtils } from "../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { Utils as SOFAccessSystemUtils } from "../src/namespaces/sofaccess/systems/sof-access-system/Utils.sol";

import { IAccessConfigSystem } from "../src/namespaces/evefrontier/interfaces/IAccessConfigSystem.sol";
import { IEntitySystem } from "../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { ISOFAccessSystem } from "../src/namespaces/sofaccesscntrl/interfaces/ISOFAccessSystem.sol";

contract EntitySystemAccessConfig is Script {

  function run(address worldAddress) public {
    IWorldKernel world = IWorldKernel(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    
    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    
    // Entity System access configurations
    // set allowClassScopedSystemOrDirectClassAccessRole for setClassAccessRole
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.setClassAccessRole.selector, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector)));
    // set allowClassAccessRole for deleteClass
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteClass.selector, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowClassAccessRole.selector)));
    // set allowClassScopedSystemOrDirectClassAccessRole for instantiate
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.instantiate.selector, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector)));
    // set allowClassScopedSystemOrDirectObjectAccessRole for setObjectAccessRole
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.setObjectAccessRole.selector, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowClassScopedSystemOrDirectObjectAccessRole.selector)));
    // set allowScopedSystemOrDirectClassAccessRole for deleteObject
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteObject.selector, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector)));

    // EntitySystem.sol toggle access enforcement on
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.setClassAccessRole.selector, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteClass.selector, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.instantiate.selector, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.setObjectAccessRole.selector, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteObject.selector, true)));

    vm.stopBroadcast();
  }
}