// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { SmartCharacterSystem } from "../../systems/smart-character/SmartCharacterSystem.sol";
import { EntityRecordData, EntityMetadata } from "../../systems/entity-record/types.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { IWorldCall } from "@latticexyz/world/src/IWorldKernel.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

type SmartCharacterSystemType is bytes32;

// equivalent to WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "evefrontier", name: "SmartCharacterSy" }))
SmartCharacterSystemType constant smartCharacterSystem = SmartCharacterSystemType.wrap(
  0x737965766566726f6e74696572000000536d6172744368617261637465725379
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
 * @title SmartCharacterSystemLib
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This library is automatically generated from the corresponding system contract. Do not edit manually.
 */
library SmartCharacterSystemLib {
  error SmartCharacterSystemLib_CallingFromRootSystem();
  error SmartCharacter_ERC721AlreadyInitialized();
  error SmartCharacter_AlreadyCreated(address characterAddress, uint256 characterId);
  error SmartCharacterDoesNotExist(uint256 characterId);

  function registerCharacterToken(SmartCharacterSystemType self, address tokenAddress) internal {
    return CallWrapper(self.toResourceId(), address(0)).registerCharacterToken(tokenAddress);
  }

  function createCharacter(
    SmartCharacterSystemType self,
    uint256 characterId,
    address characterAddress,
    uint256 tribeId,
    EntityRecordData memory entityRecord,
    EntityMetadata memory entityRecordMetadata
  ) internal {
    return
      CallWrapper(self.toResourceId(), address(0)).createCharacter(
        characterId,
        characterAddress,
        tribeId,
        entityRecord,
        entityRecordMetadata
      );
  }

  function updateTribeId(SmartCharacterSystemType self, uint256 characterId, uint256 tribeId) internal {
    return CallWrapper(self.toResourceId(), address(0)).updateTribeId(characterId, tribeId);
  }

  function registerCharacterToken(CallWrapper memory self, address tokenAddress) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert SmartCharacterSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("SmartCharacterSystem.registerCharacterToken")),
      tokenAddress
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function createCharacter(
    CallWrapper memory self,
    uint256 characterId,
    address characterAddress,
    uint256 tribeId,
    EntityRecordData memory entityRecord,
    EntityMetadata memory entityRecordMetadata
  ) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert SmartCharacterSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("SmartCharacterSystem.createCharacter")),
      characterId,
      characterAddress,
      tribeId,
      entityRecord,
      entityRecordMetadata
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function updateTribeId(CallWrapper memory self, uint256 characterId, uint256 tribeId) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert SmartCharacterSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("SmartCharacterSystem.updateTribeId")),
      characterId,
      tribeId
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function registerCharacterToken(RootCallWrapper memory self, address tokenAddress) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("SmartCharacterSystem.registerCharacterToken")),
      tokenAddress
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function createCharacter(
    RootCallWrapper memory self,
    uint256 characterId,
    address characterAddress,
    uint256 tribeId,
    EntityRecordData memory entityRecord,
    EntityMetadata memory entityRecordMetadata
  ) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("SmartCharacterSystem.createCharacter")),
      characterId,
      characterAddress,
      tribeId,
      entityRecord,
      entityRecordMetadata
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function updateTribeId(RootCallWrapper memory self, uint256 characterId, uint256 tribeId) internal {
    bytes memory systemCall = abi.encodeWithSelector(
      bytes4(keccak256("SmartCharacterSystem.updateTribeId")),
      characterId,
      tribeId
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function callFrom(SmartCharacterSystemType self, address from) internal pure returns (CallWrapper memory) {
    return CallWrapper(self.toResourceId(), from);
  }

  function callAsRoot(SmartCharacterSystemType self) internal view returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), msg.sender);
  }

  function callAsRootFrom(SmartCharacterSystemType self, address from) internal pure returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), from);
  }

  function toResourceId(SmartCharacterSystemType self) internal pure returns (ResourceId) {
    return ResourceId.wrap(SmartCharacterSystemType.unwrap(self));
  }

  function fromResourceId(ResourceId resourceId) internal pure returns (SmartCharacterSystemType) {
    return SmartCharacterSystemType.wrap(resourceId.unwrap());
  }

  function getAddress(SmartCharacterSystemType self) internal view returns (address) {
    return Systems.getSystem(self.toResourceId());
  }

  function _world() private view returns (IWorldCall) {
    return IWorldCall(StoreSwitch.getStoreAddress());
  }
}

using SmartCharacterSystemLib for SmartCharacterSystemType global;
using SmartCharacterSystemLib for CallWrapper global;
using SmartCharacterSystemLib for RootCallWrapper global;
