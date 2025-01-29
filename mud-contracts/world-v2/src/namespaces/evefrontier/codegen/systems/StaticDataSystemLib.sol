// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { StaticDataSystem } from "../../systems/static-data/StaticDataSystem.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { IWorldCall } from "@latticexyz/world/src/IWorldKernel.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

type StaticDataSystemType is bytes32;

// equivalent to WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "evefrontier", name: "StaticDataSystem" }))
StaticDataSystemType constant staticDataSystem = StaticDataSystemType.wrap(
  0x737965766566726f6e746965720000005374617469634461746153797374656d
);

struct CallWrapper {
  ResourceId systemId;
  address from;
}

struct RootCallWrapper {
  ResourceId systemId;
  address from;
}

/**
 * @title StaticDataSystemLib
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This library is automatically generated from the corresponding system contract. Do not edit manually.
 */
library StaticDataSystemLib {
  error StaticDataSystemLib_CallingFromRootSystem();

  function setCid(StaticDataSystemType self, uint256 smartObjectId, string memory cid) internal {
    return CallWrapper(self.toResourceId(), address(0)).setCid(smartObjectId, cid);
  }

  function setBaseURI(StaticDataSystemType self, string memory baseURI) internal {
    return CallWrapper(self.toResourceId(), address(0)).setBaseURI(baseURI);
  }

  function setCid(CallWrapper memory self, uint256 smartObjectId, string memory cid) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert StaticDataSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_setCid_uint256_string.setCid, (smartObjectId, cid));
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function setBaseURI(CallWrapper memory self, string memory baseURI) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert StaticDataSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_setBaseURI_string.setBaseURI, (baseURI));
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function setCid(RootCallWrapper memory self, uint256 smartObjectId, string memory cid) internal {
    bytes memory systemCall = abi.encodeCall(_setCid_uint256_string.setCid, (smartObjectId, cid));
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function setBaseURI(RootCallWrapper memory self, string memory baseURI) internal {
    bytes memory systemCall = abi.encodeCall(_setBaseURI_string.setBaseURI, (baseURI));
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function callFrom(StaticDataSystemType self, address from) internal pure returns (CallWrapper memory) {
    return CallWrapper(self.toResourceId(), from);
  }

  function callAsRoot(StaticDataSystemType self) internal view returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), msg.sender);
  }

  function callAsRootFrom(StaticDataSystemType self, address from) internal pure returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), from);
  }

  function toResourceId(StaticDataSystemType self) internal pure returns (ResourceId) {
    return ResourceId.wrap(StaticDataSystemType.unwrap(self));
  }

  function fromResourceId(ResourceId resourceId) internal pure returns (StaticDataSystemType) {
    return StaticDataSystemType.wrap(resourceId.unwrap());
  }

  function getAddress(StaticDataSystemType self) internal view returns (address) {
    return Systems.getSystem(self.toResourceId());
  }

  function _world() private view returns (IWorldCall) {
    return IWorldCall(StoreSwitch.getStoreAddress());
  }
}

/**
 * System Function Interfaces
 *
 * We generate an interface for each system function, which is then used for encoding system calls.
 * This is necessary to handle function overloading correctly (which abi.encodeCall cannot).
 *
 * Each interface is uniquely named based on the function name and parameters to prevent collisions.
 */

interface _setCid_uint256_string {
  function setCid(uint256 smartObjectId, string memory cid) external;
}

interface _setBaseURI_string {
  function setBaseURI(string memory baseURI) external;
}

using StaticDataSystemLib for StaticDataSystemType global;
using StaticDataSystemLib for CallWrapper global;
using StaticDataSystemLib for RootCallWrapper global;
