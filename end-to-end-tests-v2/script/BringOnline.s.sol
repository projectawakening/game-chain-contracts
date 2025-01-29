pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { GlobalDeployableState } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/GlobalDeployableState.sol";
import { DeployableUtils } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableUtils.sol";
import { DeployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/DeployableSystem.sol";

import { deployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/DeployableSystemLib.sol";

contract BringOnline is Script {
  // assumes CreateAndAnchor.s.sol and Deposit fuel has been run

  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);

    ResourceId deployableSystemId = DeployableUtils.deployableSystemId();
    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00001")));

    // check global state and resume if needed
    if (GlobalDeployableState.getIsPaused() == false) {
      deployableSystem.globalResume();
    }

    deployableSystem.bringOnline(smartObjectId); // needs to have some fuel in it to work, else it will just let the state to offline

    vm.stopBroadcast();
  }
}
