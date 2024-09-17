// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Module } from "@latticexyz/world/src/Module.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { InstalledModules } from "@latticexyz/world/src/codegen/tables/InstalledModules.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";

import { Puppet } from "@latticexyz/world-modules/src/modules/puppet/Puppet.sol";
import { createPuppet } from "@latticexyz/world-modules/src/modules/puppet/createPuppet.sol";

import { Utils as StaticDataUtils } from "../static-data/Utils.sol";
import { StaticDataLib } from "../static-data/StaticDataLib.sol";
import { StaticDataGlobalTableData } from "../../codegen/tables/StaticDataGlobalTable.sol";

import { STATIC_DATA_DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";
import { MODULE_NAMESPACE, MODULE_NAMESPACE_ID, ERC721_REGISTRY_TABLE_ID } from "./constants.sol";
import { Utils } from "./Utils.sol";
import { ERC721System } from "./ERC721System.sol";

import { OperatorApproval } from "../../codegen/tables/OperatorApproval.sol";
import { Owners } from "../../codegen/tables/Owners.sol";
import { TokenApproval } from "../../codegen/tables/TokenApproval.sol";
import { ERC721Registry } from "../../codegen/tables/ERC721Registry.sol";
import { Balances } from "../../codegen/tables/Balances.sol";

contract ERC721Module is Module {
  error ERC721Module_InvalidNamespace(bytes14 namespace);
  using Utils for bytes14;
  using StaticDataUtils for bytes14;
  using StaticDataLib for StaticDataLib.World;

  address immutable registrationLibrary = address(new ERC721ModuleRegistrationLibrary());

  function install(bytes memory encodedArgs) public {
    // Require the module to not be installed with these args yet
    requireNotInstalled(__self, encodedArgs);

    // Decode args
    (bytes14 namespace, StaticDataGlobalTableData memory metadata) = abi.decode(
      encodedArgs,
      (bytes14, StaticDataGlobalTableData)
    );

    // Require the namespace to not be the module's namespace
    if (namespace == MODULE_NAMESPACE) {
      revert ERC721Module_InvalidNamespace(namespace);
    }

    // Register the ERC721 tables and system
    IBaseWorld world = IBaseWorld(_world());
    (bool success, bytes memory returnData) = registrationLibrary.delegatecall(
      abi.encodeCall(ERC721ModuleRegistrationLibrary.register, (world, namespace))
    );
    if (!success) revertWithBytes(returnData);

    // Initialize the Metadata
    _staticDataLib().setMetadata(namespace.erc721SystemId(), metadata);

    // Deploy and register the ERC721 puppet.
    ResourceId erc721SystemId = namespace.erc721SystemId();
    address puppet = createPuppet(world, erc721SystemId);

    // Transfer ownership of the namespace to the caller
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    world.transferOwnership(namespaceId, _msgSender());

    // Register the ERC721 in the ERC721Registry
    if (!ResourceIds.getExists(ERC721_REGISTRY_TABLE_ID)) {
      world.registerNamespace(MODULE_NAMESPACE_ID);
      ERC721Registry.register(ERC721_REGISTRY_TABLE_ID);
    }
    ERC721Registry.set(ERC721_REGISTRY_TABLE_ID, namespaceId, puppet);
  }

  function installRoot(bytes memory) public pure {
    revert Module_RootInstallNotSupported();
  }

  function _staticDataLib() internal view returns (StaticDataLib.World memory) {
    return StaticDataLib.World({ iface: IBaseWorld(_world()), namespace: STATIC_DATA_DEPLOYMENT_NAMESPACE });
  }
}

contract ERC721ModuleRegistrationLibrary {
  using Utils for bytes14;

  /**
   * Register systems and tables for a new ERC721 token in a given namespace
   */
  function register(IBaseWorld world, bytes14 namespace) public {
    // Register the namespace if it doesn't exist yet
    ResourceId tokenNamespace = WorldResourceIdLib.encodeNamespace(namespace);
    if (!ResourceIds.getExists(tokenNamespace)) {
      world.registerNamespace(tokenNamespace);
    }

    // Register the tables
    OperatorApproval.register(namespace.operatorApprovalTableId());
    Owners.register(namespace.ownersTableId());
    TokenApproval.register(namespace.tokenApprovalTableId());
    Balances.register(namespace.balancesTableId());

    // Register a new ERC20System
    world.registerSystem(namespace.erc721SystemId(), new ERC721System(), true);
  }
}
