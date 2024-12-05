
pragma solidity >=0.8.20;

import { Script } from "forge-std/Script.sol";

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceAccess } from "@latticexyz/world/src/codegen/tables/ResourceAccess.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { FRONTIER_WORLD_DEPLOYMENT_NAMESPACE as WORLD_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";

import { Utils as AccessConfigUtils } from "../src/namespaces/evefrontier/systems/access-config-system/Utils.sol";
import { Utils as EntitySystemUtils } from "../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { Utils as TagSystemUtils } from "../src/namespaces/evefrontier/systems/tag-system/Utils.sol";
import { Utils as SOFAccessSystemUtils } from "../src/namespaces/sofaccess/systems/sof-access-system/Utils.sol";

import { IWorldWithContext } from "../src/IWorldWithContext.sol";

import { IAccessConfigSystem } from "../src/namespaces/evefrontier/interfaces/IAccessConfigSystem.sol";
import { IEntitySystem } from "../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { ISOFAccessSystem } from "../src/namespaces/sofaccesscntrl/interfaces/ISOFAccessSystem.sol";

contract EntitySystemAccessConfig is Script {

  function run(address worldAddress) public {
    IWorldWithContext world = IWorldWithContext(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    
    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    
    // Entity System access configurations
    // set allowClassAccessRole for setClassAccessRole
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.setClassAccessRole, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowClassAccessRole)));
    // set allowDirectClassAccessRole for deleteClass
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteClass, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowClassAccessRole)));
    // set allowScopedSystemOrDirectClassAccessRole for instantiate
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.instantiate, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowScopedSystemOrDirectClassAccessRole)));
    // set allowScopedSystemOrDirectClassAccessRole for deleteObject
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteObject, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowScopedSystemOrDirectClassAccessRole)));

    // Tag System access configurations
    // set allowClassAccessRole for setSystemTag
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (TagSystemUtils.tagSystemId(), ITagSystem.setSystemTag, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowEntitySystemOrDirectClassAccessRole)));
    // set allowClassAccessRole for removeSystemTag
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (TagSystemUtils.tagSystemId(), ITagSystem.deleteSystemTag, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowEntitySystemOrDirectClassAccessRole)));

    // EntitySystem.sol toggle access enforcement on
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.toggleAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.setClassAccessRole, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.toggleAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteClass, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.toggleAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.instantiate, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.toggleAccessEnforcement, (EntitySystemUtils.entitySystemId(), IEntitySystem.deleteObject, true)));

    // TagSystem.sol toggle access enforcement on
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.toggleAccessEnforcement, (TagSystemUtils.tagSystemId(), ITagSystem.setSystemTag, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.toggleAccessEnforcement, (TagSystemUtils.tagSystemId(), ITagSystem.deleteSystemTag, true)));
    vm.stopBroadcast();
  }
}