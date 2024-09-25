pragma solidity >=0.8.20;

import { Script } from "forge-std/Script.sol";

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { FRONTIER_WORLD_DEPLOYMENT_NAMESPACE as WORLD_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";

import { Utils as AccessUtils } from "../src/modules/access/Utils.sol";
import { Utils } from "../src/modules/kill-mail/Utils.sol";

import { IAccessSystem } from "../src/modules/access/interfaces/IAccessSystem.sol";
import { IKillMailSystem } from "../src/modules/kill-mail/interfaces/IKillMailSystem.sol";

contract KillMailAccessConfig is Script {
  using AccessUtils for bytes14;
  using Utils for bytes14;

  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    
    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);

    // target functions to set access control enforcement for
    // KillMailSystem
    // KillMail.reportKill
    bytes32 report = keccak256(abi.encodePacked(WORLD_NAMESPACE.killMailSystemId(), IKillMailSystem.reportKill.selector));

    // set enforcement to true for all
    world.call(WORLD_NAMESPACE.accessSystemId(), abi.encodeCall(IAccessSystem.setAccessEnforcement, (report, true)));

    vm.stopBroadcast();

  }
}