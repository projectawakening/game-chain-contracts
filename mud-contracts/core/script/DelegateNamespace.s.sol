// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { RESOURCE_NAMESPACE, RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { requireNamespace } from "@latticexyz/world/src/requireNamespace.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

import { FRONTIER_WORLD_DEPLOYMENT_NAMESPACE as DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { DelegationControlSystem } from "../src/systems/DelegationControlSystem.sol";

contract DelegateNamespace is Script {
  function run(address worldAddress) external {
    StoreSwitch.setStoreAddress(worldAddress);
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address delegatee = vm.envAddress("FORWARDER_ADDRESS");
    bytes14 erc20Namespace = vm.envString("EVE_TOKEN_NAMESPACE"); //TODO add this to the common constancts npm package and import it similar to DEPLOYMENT_NAMESPACE

    ResourceId WORLD_NAMESPACE_ID = ResourceId.wrap(
      bytes32(abi.encodePacked(RESOURCE_NAMESPACE, DEPLOYMENT_NAMESPACE))
    );
    ResourceId ERC20_NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, erc20Namespace)));

    vm.startBroadcast(deployerPrivateKey);
    requireNamespace(WORLD_NAMESPACE_ID);
    requireNamespace(ERC20_NAMESPACE_ID);
    console.log(NamespaceOwner.get(WORLD_NAMESPACE_ID));
    console.log(NamespaceOwner.get(ERC20_NAMESPACE_ID));

    DelegationControlSystem delegationControl = new DelegationControlSystem();
    ResourceId delegationControlId = delegationControlSystemId();

    IWorld(worldAddress).registerSystem(delegationControlId, delegationControl, true);

    //Delegate the World namespace to the delegatee (Forwarder contract)
    IWorld(worldAddress).registerNamespaceDelegation(
      WORLD_NAMESPACE_ID,
      delegationControlId,
      abi.encodeWithSelector(delegationControl.initDelegation.selector, WORLD_NAMESPACE_ID, delegatee)
    );
    console.log(AccessControl.hasAccess(WORLD_NAMESPACE_ID, delegatee));

    //Delegate the ERC20 namespace to the delegatee (Forwarder contract)
    IWorld(worldAddress).registerNamespaceDelegation(
      ERC20_NAMESPACE_ID,
      delegationControlId,
      abi.encodeWithSelector(delegationControl.initDelegation.selector, ERC20_NAMESPACE_ID, delegatee)
    );

    vm.stopBroadcast();
  }

  function delegationControlSystemId() internal pure returns (ResourceId) {
    return
      WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: DEPLOYMENT_NAMESPACE, name: "DelegationContr" });
  }
}
