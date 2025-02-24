// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EveSystem } from "../../systems/EveSystem.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { IWorldCall } from "@latticexyz/world/src/IWorldKernel.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

type EveSystemType is bytes32;

// equivalent to WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "evefrontier", name: "EveSystem" }))
EveSystemType constant eveSystem = EveSystemType.wrap(
  0x737965766566726f6e7469657200000045766553797374656d00000000000000
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
 * @title EveSystemLib
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This library is automatically generated from the corresponding system contract. Do not edit manually.
 */
library EveSystemLib {
  error EveSystemLib_CallingFromRootSystem();

  function registerSmartCharacterClass(EveSystemType self, uint256 typeId) internal {
    return CallWrapper(self.toResourceId(), address(0)).registerSmartCharacterClass(typeId);
  }

  function registerSmartStorageUnitClass(EveSystemType self, uint256 typeId) internal {
    return CallWrapper(self.toResourceId(), address(0)).registerSmartStorageUnitClass(typeId);
  }

  function registerSmartTurretClass(EveSystemType self, uint256 typeId) internal {
    return CallWrapper(self.toResourceId(), address(0)).registerSmartTurretClass(typeId);
  }

  function registerSmartGateClass(EveSystemType self, uint256 typeId) internal {
    return CallWrapper(self.toResourceId(), address(0)).registerSmartGateClass(typeId);
  }

  function configureEntityRecordAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureEntityRecordAccess();
  }

  function configureStaticDataAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureStaticDataAccess();
  }

  function configureSmartAssemblyAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureSmartAssemblyAccess();
  }

  function configureSmartCharacterAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureSmartCharacterAccess();
  }

  function configureLocationAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureLocationAccess();
  }

  function configureFuelAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureFuelAccess();
  }

  function configureDeployableAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureDeployableAccess();
  }

  function configureInventoryAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureInventoryAccess();
  }

  function configureEphemeralInventoryAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureEphemeralInventoryAccess();
  }

  function configureInventoryInteractAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureInventoryInteractAccess();
  }

  function configureSmartStorageUnitAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureSmartStorageUnitAccess();
  }

  function configureSmartTurretAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureSmartTurretAccess();
  }

  function configureSmartGateAccess(EveSystemType self) internal {
    return CallWrapper(self.toResourceId(), address(0)).configureSmartGateAccess();
  }

  function registerSmartCharacterClass(CallWrapper memory self, uint256 typeId) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _registerSmartCharacterClass_uint256.registerSmartCharacterClass,
      (typeId)
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function registerSmartStorageUnitClass(CallWrapper memory self, uint256 typeId) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _registerSmartStorageUnitClass_uint256.registerSmartStorageUnitClass,
      (typeId)
    );
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function registerSmartTurretClass(CallWrapper memory self, uint256 typeId) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_registerSmartTurretClass_uint256.registerSmartTurretClass, (typeId));
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function registerSmartGateClass(CallWrapper memory self, uint256 typeId) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_registerSmartGateClass_uint256.registerSmartGateClass, (typeId));
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureEntityRecordAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureEntityRecordAccess.configureEntityRecordAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureStaticDataAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureStaticDataAccess.configureStaticDataAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureSmartAssemblyAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureSmartAssemblyAccess.configureSmartAssemblyAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureSmartCharacterAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureSmartCharacterAccess.configureSmartCharacterAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureLocationAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureLocationAccess.configureLocationAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureFuelAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureFuelAccess.configureFuelAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureDeployableAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureDeployableAccess.configureDeployableAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureInventoryAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureInventoryAccess.configureInventoryAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureEphemeralInventoryAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureEphemeralInventoryAccess.configureEphemeralInventoryAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureInventoryInteractAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureInventoryInteractAccess.configureInventoryInteractAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureSmartStorageUnitAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureSmartStorageUnitAccess.configureSmartStorageUnitAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureSmartTurretAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureSmartTurretAccess.configureSmartTurretAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function configureSmartGateAccess(CallWrapper memory self) internal {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert EveSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_configureSmartGateAccess.configureSmartGateAccess, ());
    self.from == address(0)
      ? _world().call(self.systemId, systemCall)
      : _world().callFrom(self.from, self.systemId, systemCall);
  }

  function registerSmartCharacterClass(RootCallWrapper memory self, uint256 typeId) internal {
    bytes memory systemCall = abi.encodeCall(
      _registerSmartCharacterClass_uint256.registerSmartCharacterClass,
      (typeId)
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function registerSmartStorageUnitClass(RootCallWrapper memory self, uint256 typeId) internal {
    bytes memory systemCall = abi.encodeCall(
      _registerSmartStorageUnitClass_uint256.registerSmartStorageUnitClass,
      (typeId)
    );
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function registerSmartTurretClass(RootCallWrapper memory self, uint256 typeId) internal {
    bytes memory systemCall = abi.encodeCall(_registerSmartTurretClass_uint256.registerSmartTurretClass, (typeId));
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function registerSmartGateClass(RootCallWrapper memory self, uint256 typeId) internal {
    bytes memory systemCall = abi.encodeCall(_registerSmartGateClass_uint256.registerSmartGateClass, (typeId));
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureEntityRecordAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureEntityRecordAccess.configureEntityRecordAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureStaticDataAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureStaticDataAccess.configureStaticDataAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureSmartAssemblyAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureSmartAssemblyAccess.configureSmartAssemblyAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureSmartCharacterAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureSmartCharacterAccess.configureSmartCharacterAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureLocationAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureLocationAccess.configureLocationAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureFuelAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureFuelAccess.configureFuelAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureDeployableAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureDeployableAccess.configureDeployableAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureInventoryAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureInventoryAccess.configureInventoryAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureEphemeralInventoryAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureEphemeralInventoryAccess.configureEphemeralInventoryAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureInventoryInteractAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureInventoryInteractAccess.configureInventoryInteractAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureSmartStorageUnitAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureSmartStorageUnitAccess.configureSmartStorageUnitAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureSmartTurretAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureSmartTurretAccess.configureSmartTurretAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function configureSmartGateAccess(RootCallWrapper memory self) internal {
    bytes memory systemCall = abi.encodeCall(_configureSmartGateAccess.configureSmartGateAccess, ());
    SystemCall.callWithHooksOrRevert(self.from, self.systemId, systemCall, msg.value);
  }

  function callFrom(EveSystemType self, address from) internal pure returns (CallWrapper memory) {
    return CallWrapper(self.toResourceId(), from);
  }

  function callAsRoot(EveSystemType self) internal view returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), msg.sender);
  }

  function callAsRootFrom(EveSystemType self, address from) internal pure returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), from);
  }

  function toResourceId(EveSystemType self) internal pure returns (ResourceId) {
    return ResourceId.wrap(EveSystemType.unwrap(self));
  }

  function fromResourceId(ResourceId resourceId) internal pure returns (EveSystemType) {
    return EveSystemType.wrap(resourceId.unwrap());
  }

  function getAddress(EveSystemType self) internal view returns (address) {
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

interface _registerSmartCharacterClass_uint256 {
  function registerSmartCharacterClass(uint256 typeId) external;
}

interface _registerSmartStorageUnitClass_uint256 {
  function registerSmartStorageUnitClass(uint256 typeId) external;
}

interface _registerSmartTurretClass_uint256 {
  function registerSmartTurretClass(uint256 typeId) external;
}

interface _registerSmartGateClass_uint256 {
  function registerSmartGateClass(uint256 typeId) external;
}

interface _configureEntityRecordAccess {
  function configureEntityRecordAccess() external;
}

interface _configureStaticDataAccess {
  function configureStaticDataAccess() external;
}

interface _configureSmartAssemblyAccess {
  function configureSmartAssemblyAccess() external;
}

interface _configureSmartCharacterAccess {
  function configureSmartCharacterAccess() external;
}

interface _configureLocationAccess {
  function configureLocationAccess() external;
}

interface _configureFuelAccess {
  function configureFuelAccess() external;
}

interface _configureDeployableAccess {
  function configureDeployableAccess() external;
}

interface _configureInventoryAccess {
  function configureInventoryAccess() external;
}

interface _configureEphemeralInventoryAccess {
  function configureEphemeralInventoryAccess() external;
}

interface _configureInventoryInteractAccess {
  function configureInventoryInteractAccess() external;
}

interface _configureSmartStorageUnitAccess {
  function configureSmartStorageUnitAccess() external;
}

interface _configureSmartTurretAccess {
  function configureSmartTurretAccess() external;
}

interface _configureSmartGateAccess {
  function configureSmartGateAccess() external;
}

using EveSystemLib for EveSystemType global;
using EveSystemLib for CallWrapper global;
using EveSystemLib for RootCallWrapper global;
