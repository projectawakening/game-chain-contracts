// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityRecordSystem } from "../../systems/entity-record/EntityRecordSystem.sol";
import { EntityRecordData, EntityMetadata } from "../../systems/entity-record/types.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { IWorldCall } from "@latticexyz/world/src/IWorldKernel.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

type EntityRecordSystemType is bytes32;

// equivalent to WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "evefrontier", name: "EntityRecordSyst" }))
EntityRecordSystemType constant entityRecordSystem = EntityRecordSystemType.wrap(
  0x737965766566726f6e74696572000000456e746974795265636f726453797374
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
 * @title EntityRecordSystemLib
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This library is automatically generated from the corresponding system contract. Do not edit manually.
 */
library EntityRecordSystemLib {
  error EntityRecordSystemLib_CallingFromRootSystem();

  function createEntityRecord(
    EntityRecordSystemType self,
    uint256 smartObjectId,
    EntityRecordData memory entityRecord
  ) internal {
    return CallWrapper(self.toResourceId(), address(0)).createEntityRecord(smartObjectId, entityRecord);
  }

  function createEntityRecordMetadata(
    EntityRecordSystemType self,
    uint256 smartObjectId,
    EntityMetadata memory entityRecordMetadata
  ) internal {
    return CallWrapper(self.toResourceId(), address(0)).createEntityRecordMetadata(smartObjectId, entityRecordMetadata);
  }

  function setName(EntityRecordSystemType self, uint256 smartObjectId, string memory name) internal {
    return CallWrapper(self.toResourceId(), address(0)).setName(smartObjectId, name);
  }

  function setDappURL(EntityRecordSystemType self, uint256 smartObjectId, string memory dappURL) internal {
    return CallWrapper(self.toResourceId(), address(0)).setDappURL(smartObjectId, dappURL);
  }

  function setDescription(EntityRecordSystemType self, uint256 smartObjectId, string memory description) internal {
    return CallWrapper(self.toResourceId(), address(0)).setDescription(smartObjectId, description);
  }

  function createEntityRecord(
    CallWrapper memory self,
    uint256 smartObjectId,
    EntityRecordData memory entityRecord
  ) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EntityRecordSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.createEntityRecord")),
      smartObjectId,
      entityRecord
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function createEntityRecordMetadata(
    CallWrapper memory self,
    uint256 smartObjectId,
    EntityMetadata memory entityRecordMetadata
  ) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EntityRecordSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.createEntityRecordMetadata")),
      smartObjectId,
      entityRecordMetadata
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function setName(CallWrapper memory self, uint256 smartObjectId, string memory name) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EntityRecordSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.setName")),
      smartObjectId,
      name
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function setDappURL(CallWrapper memory self, uint256 smartObjectId, string memory dappURL) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EntityRecordSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.setDappURL")),
      smartObjectId,
      dappURL
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function setDescription(CallWrapper memory self, uint256 smartObjectId, string memory description) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EntityRecordSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.setDescription")),
      smartObjectId,
      description
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function createEntityRecord(
    RootCallWrapper memory self,
    uint256 smartObjectId,
    EntityRecordData memory entityRecord
  ) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.createEntityRecord")),
      smartObjectId,
      entityRecord
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function createEntityRecordMetadata(
    RootCallWrapper memory self,
    uint256 smartObjectId,
    EntityMetadata memory entityRecordMetadata
  ) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.createEntityRecordMetadata")),
      smartObjectId,
      entityRecordMetadata
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function setName(RootCallWrapper memory self, uint256 smartObjectId, string memory name) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.setName")),
      smartObjectId,
      name
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function setDappURL(RootCallWrapper memory self, uint256 smartObjectId, string memory dappURL) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.setDappURL")),
      smartObjectId,
      dappURL
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function setDescription(RootCallWrapper memory self, uint256 smartObjectId, string memory description) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("EntityRecordSystem.setDescription")),
      smartObjectId,
      description
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function callFrom(EntityRecordSystemType self, address from) internal pure returns (CallWrapper memory) {
    return CallWrapper(self.toResourceId(), from);
  }

  function callAsRoot(EntityRecordSystemType self) internal view returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), msg.sender);
  }

  function callAsRootFrom(EntityRecordSystemType self, address from) internal pure returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), from);
  }

  function toResourceId(EntityRecordSystemType self) internal pure returns (ResourceId) {
    return ResourceId.wrap(EntityRecordSystemType.unwrap(self));
  }

  function fromResourceId(ResourceId resourceId) internal pure returns (EntityRecordSystemType) {
    return EntityRecordSystemType.wrap(resourceId.unwrap());
  }

  function getAddress(EntityRecordSystemType self) internal view returns (address) {
    return Systems.getSystem(self.toResourceId());
  }

  function _world() private view returns (IWorldCall) {
    return IWorldCall(StoreSwitch.getStoreAddress());
  }
}

using EntityRecordSystemLib for EntityRecordSystemType global;
using EntityRecordSystemLib for CallWrapper global;
using EntityRecordSystemLib for RootCallWrapper global;
