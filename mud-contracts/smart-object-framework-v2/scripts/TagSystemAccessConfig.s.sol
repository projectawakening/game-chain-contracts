// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import { Script } from "forge-std/Script.sol";

import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceAccess } from "@latticexyz/world/src/codegen/tables/ResourceAccess.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { FRONTIER_WORLD_DEPLOYMENT_NAMESPACE as WORLD_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";

import { Utils as AccessConfigUtils } from "../src/namespaces/evefrontier/systems/access-config-system/Utils.sol";
import { Utils as TagSystemUtils } from "../src/namespaces/evefrontier/systems/tag-system/Utils.sol";
import { Utils as SOFAccessSystemUtils } from "../src/namespaces/sofaccess/systems/sof-access-system/Utils.sol";

import { IAccessConfigSystem } from "../src/namespaces/evefrontier/interfaces/IAccessConfigSystem.sol";
import { ITagSystem } from "../src/namespaces/evefrontier/interfaces/ITagSystem.sol";
import { ISOFAccessSystem } from "../src/namespaces/sofaccesscntrl/interfaces/ISOFAccessSystem.sol";

contract TagSystemAccessConfig is Script {

  function run(address worldAddress) public {
    IWorldKernel world = IWorldKernel(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    
    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    
    // Tag System access configurations
    // set allowEntitySystemOrDirectAccessRole for setSystemTag
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (TagSystemUtils.tagSystemId(), ITagSystem.setSystemTag.selector, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowEntitySystemOrDirectAccessRole.selector)));
    // set allowEntitySystemOrDirectAccessRole for removeSystemTag
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.configureAccess, (TagSystemUtils.tagSystemId(), ITagSystem.removeSystemTag.selector, SOFAccessControlSystemUtils.sofAccessSystemId(), ISOFAccessSystem.allowEntitySystemOrDirectAccessRole.selector)));

    // TagSystem.sol toggle access enforcement on
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (TagSystemUtils.tagSystemId(), ITagSystem.setSystemTag.selector, true)));
    world.call(AccessConfigUtils.accessConfigSystemId(), abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (TagSystemUtils.tagSystemId(), ITagSystem.removeSystemTag.selector, true)));

    vm.stopBroadcast();
  }
}