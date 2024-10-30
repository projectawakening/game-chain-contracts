pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { FuelSystem } from "@eveworld/world-v2/src/systems/fuel/FuelSystem.sol";
import { FuelUtils } from "@eveworld/world-v2/src/systems/fuel/FuelUtils.sol";

contract DepositFuel is Script {
  function run(address worldAddress) public {
    StoreSwitch.setStoreAddress(worldAddress);
    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);
    IBaseWorld world = IBaseWorld(worldAddress);

    ResourceId fuelSystemId = FuelUtils.fuelSystemId();

    uint256 smartObjectId = uint256(keccak256(abi.encode("item:<tenant_id>-<db_id>-00001")));
    world.call(fuelSystemId, abi.encodeCall(FuelSystem.depositFuel, (smartObjectId, 1000)));

    vm.stopBroadcast();
  }
}
